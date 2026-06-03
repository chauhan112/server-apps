# K3s HA Cluster Status & Migration Roadmap

## 1. Current Cluster Context & Topology

### Networking Standards
* **Tailnet:** Standardized on the `ichbinsternchen43` Tailscale account. All cluster nodes communicate securely over the `tailscale0` virtual interface using `100.x.y.z` IPs.

### Node Inventory & Status

| Node Name | Device Type | Tailscale IP | Role | Status |
| :--- | :--- | :--- | :--- | :--- |
| **katana** | Gaming Laptop | `100.112.171.27` | Server (Leader) | **Ready** (etcd initialized) |
| **raja-mini-pc** | Mini PC | `100.77.37.49` | Server (Member) | **Ready** (Joined & Synced) |
| **rp** | Raspberry Pi | `100.100.171.76` | Server (Pending) | **Awaiting Cgroup Fix** |

### Troubleshooting Summary (What We Fixed)
1. **API IP Bindings:** Adjusted K3s on `katana` to bind to its Tailscale IP (`100.112.171.27`) instead of its local physical IP (`192.168.178.21`) so remote nodes can connect.
2. **Tailscale Alignment:** Resolved a multi-tenant conflict where the Mini PC was stuck on an old account (`balibabu403`). Performed a hard reset of `tailscaled` on the Mini PC and joined it to `ichbinsternchen43`.
3. **Database Syncing:** Observed and allowed the initial 7.7 MB `etcd` database snapshot to transfer from `katana` to `raja-mini-pc` over Tailscale (completed in ~31 seconds).
4. **Pi Cgroups Limitation:** Identified that the Raspberry Pi fails to boot K3s because the Linux kernel on ARM64 lacks memory cgroups enabled by default.

---

## 2. Next Steps: Execution Plan

### Step 1: Connect Raspberry Pi as the 3rd Master Node
Once the Raspberry Pi reboots with memory cgroups enabled, execute the cluster join command:

1. Confirm the Raspberry Pi is back online and logged into the correct Tailscale account:
   ```bash
   tailscale status
   ```
2. Fetch the bootstrap script using the local LAN IP (fastest for downloading the binary) with `role=server`:
   ```bash
   curl -sfL "http://192.168.178.21:8082/bootstrap?role=server" | sudo sh
   ```
3. Verify that your 3-node HA Control Plane is healthy by running this on **katana**:
   ```bash
   sudo kubectl get nodes -o wide
   ```
   *All three nodes (`katana`, `raja-mini-pc`, and `rp`) should appear in a `Ready` state.*

---

### Step 2: Understanding Data Management in a Kubernetes Cluster
Kubernetes treats storage differently depending on the type of data. In your HA cluster, data falls into two main categories:

#### A. Unstructured Data (Images, Media, File Uploads)
* **The Kubernetes Way:** In a multi-node cluster, if a pod running Directus restarts or moves from the Mini PC to the Gaming Laptop, it must still be able to access the exact same files (e.g., product images).
* **The Solution:** 
  1. **Directus Native S3 Storage (Recommended):** Directus has built-in support for S3-compatible backends [1]. You should configure Directus to write file uploads directly to a **Cloudflare R2 bucket**. This removes the need to sync local storage paths across nodes.
  2. **Longhorn ReadWriteMany (Alternative):** If you must keep files on local drives, you can use Longhorn volumes with `ReadWriteMany` (RWX) sharing, backed by an NFS-like export service running automatically inside the cluster.

#### B. Structured Data (Database Content)
* **The Kubernetes Way:** Databases (PostgreSQL, MariaDB, or SQLite) require low-latency, highly consistent storage.
* **The Solution:** Use **Longhorn Persistent Volume Claims (PVC)** set to `ReadWriteOnce` (RWO). 
  * Longhorn will automatically replicate the database files across your always-on nodes (Gaming Laptop and Mini PC).
  * *Note: We will exclude the Raspberry Pi from database replication to save its SD card from write wear and CPU fatigue.*

---

### Step 3: Backup Strategy & The Downloadable .zip API
You want a simple API endpoint or script where you can download a `.zip` file of your database backup.

#### How backups are handled in K3s:
1. **Database Level (Logical Backups):**
   * We will run a **Kubernetes CronJob** (a scheduled task inside your cluster).
   * Every night, this job will run `pg_dump` (or similar DB-dump commands) to generate a `.sql` file, compress it into a `.zip` or `.tar.gz` archive along with any local files, and upload it to a private folder in your **Cloudflare R2 bucket**.
2. **Accessing/Downloading the Backups:**
   * **Direct S3/R2 Link (Easiest):** Since the backups are placed in Cloudflare R2, you can log into the Cloudflare dashboard to download them, or use a simple CLI command (`aws s3 cp`).
   * **Direct Custom API Service (Your Request):** We can deploy a lightweight helper service inside the cluster (e.g., a simple secure Python/Node container) exposed via your Cloudflare Tunnel. 
     * When you hit `https://backups.yourdomain.com/download-latest`, the service securely generates a signed Cloudflare R2 download URL or streams the latest `.zip` file directly to your browser.

---

### Step 4: Migrate Directus from Raspberry Pi to the Cluster

#### Phase A: Export Existing Data from the Pi
Before deploying Directus inside the cluster, extract your current data from the standalone Raspberry Pi instance:
1. **Export the database:** Dump the SQLite or PostgreSQL database currently running on the Pi.
2. **Compress assets:** Create an archive of your current uploads folder:
   ```bash
   tar -czf directus-uploads.tar.gz /path/to/directus/uploads
   ```

#### Phase B: Deploy the Database in K3s
1. Define a PostgreSQL (or MariaDB) deployment YAML backed by a Longhorn storage volume.
2. Apply the deployment and import the database backup file into your new cluster database.

#### Phase C: Deploy Directus in K3s
1. Deploy Directus using a deployment YAML.
2. Point its environment variables to the new database inside the cluster.
3. Configure the media storage variables to target your Cloudflare R2 bucket.
4. Upload your existing assets (`directus-uploads.tar.gz`) directly to your Cloudflare R2 bucket.