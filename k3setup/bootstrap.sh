#!/bin/sh
set -e
echo "=== Starting Automated Device Provisioning ==="

OS="$(uname)"
ARCH="$(uname -m)"

# Dynamic role injected by the Flask server ('server' or 'agent')
ROLE="{{ ROLE }}"

if [ "$OS" = "Darwin" ]; then
    echo "System: macOS ($ARCH) detected."
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install tailscale
    sudo tailscaled --state=local &
    sleep 3
    tailscale up --authkey={{ TAILSCALE_KEY }} --accept-dns=true --reset
    echo "macOS connected to network. (K3s requires a VM to run on macOS)."
else
    echo "System: Linux ($ARCH) detected."
    
    # 1. Install and start Tailscale
    curl -sfL https://tailscale.com/install.sh | sh
    tailscale up --authkey={{ TAILSCALE_KEY }} --accept-dns=true --reset
    
    # 2. Extract the local Tailscale IP dynamically
    TS_IP=$(tailscale ip -4)
    echo "Provisioning using Tailscale IP: $TS_IP"

    if [ "$ROLE" = "server" ]; then
        echo "Configuring node to join the HA Control Plane..."
        
        # Write clean declarative config for the new Master/Server node
        sudo mkdir -p /etc/rancher/k3s
        sudo tee /etc/rancher/k3s/config.yaml > /dev/null <<EOF
server: "https://{{ MASTER_IP }}:6443"
token: "{{ K3S_TOKEN }}"
node-ip: "$TS_IP"
node-external-ip: "$TS_IP"
advertise-address: "$TS_IP"
flannel-iface: "tailscale0"
tls-san:
  - "$TS_IP"
EOF

        # Install K3s in server (control-plane) mode
        curl -sfL https://get.k3s.io | sh -
        
    else
        echo "Configuring node to join as a Worker Agent..."
        
        # Install K3s in agent (worker) mode with Tailscale configurations
        curl -sfL https://get.k3s.io | K3S_URL=https://{{ MASTER_IP }}:6443 K3S_TOKEN={{ K3S_TOKEN }} sh -s - agent \
            --node-ip "$TS_IP" \
            --node-external-ip "$TS_IP" \
            --flannel-iface "tailscale0" \
            --node-label "arch=$ARCH"
    fi
fi

echo "=== Setup Complete! ==="