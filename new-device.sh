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

# Ensure global npm binaries are in PATH for this session
export PATH="$(npm config get prefix)/bin:$PATH"

# --- 6. Install code-server ---
echo "💻 Installing code-server..."
if [ "$ENV" == "termux" ]; then
    pkg install -y code-server
else
    curl -fsSL https://code-server.dev/install.sh | sh
    
    # Stop and disable systemd service to avoid conflicts with PM2
    if systemctl is-active --quiet code-server@$USER 2>/dev/null; then
        echo "🛑 Stopping existing systemd service..."
        $SUDO systemctl disable --now code-server@$USER 2>/dev/null || true
    fi
    
    # Optional: Open firewall port 8080 if ufw is present
    if command -v ufw >/dev/null; then
        $SUDO ufw allow 8080
    fi
fi

# --- 7. Configure & Start code-server with PM2 ---
echo "⚙️ Starting code-server with PM2..."
CODE_SERVER_PATH=$(command -v code-server)

if [ -n "$CODE_SERVER_PATH" ]; then
    # Delete old process if it already exists to avoid duplicates
    pm2 delete code-server 2>/dev/null || true
    
    # Start code-server using PM2 (runs directly as a binary executable)
    # The --bind-addr flag immediately makes it available on your local network
    pm2 start "$CODE_SERVER_PATH" --name "code-server" --interpreter none -- --bind-addr 0.0.0.0:8080
    
    # Wait briefly for config file generation
    sleep 2
    
    # Save the PM2 process list
    pm2 save
else
    echo "❌ Error: code-server executable not found."
fi

# --- 8. Summary & Help ---
echo ""
echo "===================================================="
echo "✅ INSTALLATION COMPLETE"
echo "===================================================="
echo "📦 Node: $(node -v)"
echo "📦 PM2:  $(pm2 -v | grep -o '[0-9.]*')"
[ -f "$HOME/.bun/bin/bun" ] && echo "📦 Bun:  $(~/.bun/bin/bun --version)"
[ -n "$CODE_SERVER_PATH" ] && echo "📦 Code: $(code-server --version | awk '{print $1}')"
echo "===================================================="

# Determine IP address
if [ "$ENV" == "linux" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
else
    IP_ADDR=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' || hostname -I | awk '{print $1}')
    [ -z "$IP_ADDR" ] && IP_ADDR="127.0.0.1"
fi

# Try to extract the auto-generated password
PASSWORD=$(grep "password:" ~/.config/code-server/config.yaml 2>/dev/null | awk '{print $2}')

echo "👉 VS Code Server is running in the background via PM2."
echo "👉 Web URL:  http://$IP_ADDR:8080"
if [ -n "$PASSWORD" ]; then
    echo "👉 Password: $PASSWORD"
else
    echo "👉 Password config is located in: ~/.config/code-server/config.yaml"
fi
echo ""
echo "🔄 PM2 Management Commands:"
echo "   - View status:  pm2 status"
echo "   - View logs:    pm2 logs code-server"
echo "   - Restart:      pm2 restart code-server"
echo ""

if [ "$ENV" == "linux" ]; then
    echo "⚙️  To run PM2 automatically on system boot:"
    echo "   1. Run command:  pm2 startup"
    echo "   2. Copy and run the exact command it outputs on the screen."
    echo "   3. Run command:  pm2 save"
else
    echo "👉 In Termux, run 'termux-wake-lock' to prevent Android from killing background tasks."
fi

# Refresh shell
echo ""
echo "💡 Run 'source ~/.bashrc' to enable Bun in this terminal."