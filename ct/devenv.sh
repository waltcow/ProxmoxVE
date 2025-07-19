#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/waltcow/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ubuntu.com/

APP="Development Environment"
var_tags="${var_tags:-development;tools}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /var ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  $STD apt-get update
  $STD apt-get -y upgrade
  
  # Update Node.js to latest
  msg_info "Updating Node.js to latest version"
  curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
  $STD apt-get install -y nodejs
  
  # Update Go if new version available
  CURRENT_GO_VERSION=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
  LATEST_GO_VERSION=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version' | sed 's/go//')
  if [[ "$CURRENT_GO_VERSION" != "$LATEST_GO_VERSION" ]]; then
    msg_info "Updating Go from $CURRENT_GO_VERSION to $LATEST_GO_VERSION"
    cd /tmp
    curl -fsSL -o go.tar.gz https://mirrors.aliyun.com/golang/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz
    msg_ok "Updated Go to $LATEST_GO_VERSION"
  fi
  
  # Update global npm packages
  msg_info "Updating global npm packages"
  $STD npm update -g
  
  msg_ok "Updated ${APP} LXC"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${TAB}${YELLOW}Access your development environment via SSH${CL}"
echo -e "${TAB}${YELLOW}Username: root${CL}"
echo -e "${TAB}${YELLOW}Default shell: zsh${CL}"
echo -e "${TAB}${YELLOW}Installed tools: Node.js, Go, GitHub CLI, Claude CLI, PostgreSQL client, MySQL client${CL}"