write-kubeconfig-mode: "0644"
cluster-init: true
token: "222fc56cedeb4a0bbf1786a5e1dc7872"

# Networking bindings for Tailscale
node-ip: "100.112.171.27"
node-external-ip: "100.112.171.27"
advertise-address: "100.112.171.27"
flannel-iface: "tailscale0"

# Cert registration for external access
tls-san:
  - "100.112.171.27"