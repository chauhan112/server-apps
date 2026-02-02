#!/bin/bash

# install bun, pm2, and code-server on a new device
# --- 1. Identify Environment ---
if [ -d "/data/data/com.termux/files/usr" ]; then
    ENV="termux"
    SUDO=""
    echo "🎯 Environment: Termux"
else
    ENV="linux"
    SUDO="sudo"
    echo "🎯 Environment: Linux (Ubuntu/Pi)"
fi

# --- 2. Check Architecture ---
ARCH=$(uname -m)
echo "🏗️  Architecture: $ARCH"

# --- 3. Update & Install Base Dependencies ---
echo "🔄 Updating system..."
if [ "$ENV" == "termux" ]; then
    pkg update && pkg upgrade -y
    pkg install -y nodejs-lts python git wget curl build-essential tur-repo unzip
else
    $SUDO apt update && $SUDO apt upgrade -y
    $SUDO apt install -y curl wget unzip build-essential git
    
    # Install modern Node.js (v20 LTS) for Ubuntu/Pi
    echo "🟢 Installing Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
    $SUDO apt install -y nodejs
fi

# --- 4. Install Bun ---
echo "⚡ Installing Bun..."
if [[ "$ARCH" == "aarch64" || "$ARCH" == "x86_64" ]]; then
    curl -fsSL https://bun.sh/install | bash
    # Export path for the current script session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    echo "⚠️ Skipping Bun: Architecture $ARCH not supported (64-bit required)."
fi

# --- 5. Install PM2 ---
echo "🚀 Installing PM2..."
$SUDO npm install -g pm2

# --- 6. Install code-server ---
echo "💻 Installing code-server..."
if [ "$ENV" == "termux" ]; then
    pkg install -y code-server
else
    curl -fsSL https://code-server.dev/install.sh | sh
    $SUDO systemctl enable --now code-server@$USER
    
    # Optional: Open firewall port 8080 if ufw is present
    if command -v ufw >/dev/null; then
        $SUDO ufw allow 8080
    fi
fi

# --- 7. Summary & Help ---
echo ""
echo "===================================================="
echo "✅ INSTALLATION COMPLETE"
echo "===================================================="
echo "📦 Node: $(node -v)"
echo "📦 PM2:  $(pm2 -v | grep -o '[0-9.]*')"
[ -f "$HOME/.bun/bin/bun" ] && echo "📦 Bun:  $(~/.bun/bin/bun --version)"
echo "📦 Code: $(code-server --version | awk '{print $1}')"
echo "===================================================="

if [ "$ENV" == "linux" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo "👉 To access VS Code remotely:"
    echo "   1. Edit config: nano ~/.config/code-server/config.yaml"
    echo "   2. Change 'bind-addr: 127.0.0.1:8080' to '0.0.0.0:8080'"
    echo "   3. Restart: sudo systemctl restart code-server@$USER"
    echo "   4. Visit: http://$IP_ADDR:8080"
else
    echo "👉 In Termux, run 'code-server' to start."
    echo "👉 Use 'termux-wake-lock' to prevent Android from killing background tasks."
fi

# Refresh shell
echo "💡 Run 'source ~/.bashrc' to enable Bun in this terminal."