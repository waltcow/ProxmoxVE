#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ubuntu.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Fix locale settings
msg_info "Configuring locale settings"
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
msg_ok "Locale configured"

# Set timezone
msg_info "Setting timezone to America/Los_Angeles"
export TZ=America/Los_Angeles
echo $TZ > /etc/timezone
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
msg_ok "Timezone set"

# Update package sources to use Aliyun mirrors
msg_info "Configuring package mirrors"
sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources
$STD apt-get update
msg_ok "Package mirrors configured"

# Install base packages
msg_info "Installing base packages"
$STD apt-get install -y \
    locales \
    curl \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    sudo \
    git \
    less \
    procps \
    zsh \
    man-db \
    unzip \
    aggregate \
    jq \
    openssh-server \
    screen \
    tmux \
    postgresql-client \
    mysql-client
msg_ok "Base packages installed"

# Install Node.js (latest)
msg_info "Installing Node.js (latest)"
curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
$STD apt-get install -y nodejs
msg_ok "Node.js installed"

# Install Go
msg_info "Installing Go 1.24.4"
GO_VERSION=1.24.4
curl -fsSL -o /tmp/go.tar.gz https://mirrors.aliyun.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
echo 'export PATH="/usr/local/go/bin:$PATH"' >> /etc/profile
msg_ok "Go installed"

# Set environment variables
msg_info "Setting environment variables"
cat << 'EOF' >> /etc/profile
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
export NPM_CONFIG_PREFIX=/usr/local/share/npm-global
export PATH=$PATH:/usr/local/share/npm-global/bin
EOF
msg_ok "Environment variables set"

# Install GitHub CLI
msg_info "Installing GitHub CLI"
mkdir -p -m 755 /etc/apt/keyrings
wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
cat /tmp/githubcli-archive-keyring.gpg > /etc/apt/keyrings/githubcli-archive-keyring.gpg
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
$STD apt-get update
$STD apt-get install -y gh
rm -f /tmp/githubcli-archive-keyring.gpg
msg_ok "GitHub CLI installed"

# Create directories with proper permissions
msg_info "Creating workspace directories"
mkdir -p /workspace /root/.claude
mkdir -p /usr/local/share/npm-global
msg_ok "Directories created"

# Persist bash history
msg_info "Setting up persistent bash history"
mkdir -p /commandhistory
touch /commandhistory/.bash_history
echo 'export PROMPT_COMMAND="history -a"' >> /etc/profile
echo 'export HISTFILE=/commandhistory/.bash_history' >> /etc/profile
msg_ok "Bash history configured"

# Install global npm packages
msg_info "Installing global npm packages"
source /etc/profile
npm install -g @anthropic-ai/claude-code@1.0.51
npm install -g ccusage
npm install -g pnpm
msg_ok "Global npm packages installed"

# Install and configure Zsh with Oh My Zsh
msg_info "Installing and configuring Zsh with Oh My Zsh"
# Install Oh My Zsh for root
export HOME=/root
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure Zsh plugins
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc

# Add Go paths to zshrc
cat << 'EOF' >> /root/.zshrc

# --- Go paths ---
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
EOF

# Set zsh as default shell
chsh -s /bin/zsh
msg_ok "Zsh configured"

# Configure SSH
msg_info "Configuring SSH"
systemctl enable ssh
systemctl start ssh
msg_ok "SSH configured"

# Set working directory
msg_info "Setting workspace"
echo 'cd /workspace' >> /root/.zshrc
msg_ok "Workspace set"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"