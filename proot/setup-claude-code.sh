#!/bin/bash
# Run INSIDE the Ubuntu proot-distro container (`proot-distro login ubuntu`)
# -- installs Node (via NodeSource, matching the A17's v24) and Claude
# Code itself, and writes claude-session.sh into place. install.sh (the
# one at the repo root, run from real Termux) calls this for you.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if ! command -v node >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl ca-certificates git tmux
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y nodejs
fi
command -v tmux >/dev/null 2>&1 || apt-get install -y tmux

npm install -g @anthropic-ai/claude-code

mkdir -p /root/bin
cp "$(dirname "$0")/claude-session.sh" /root/bin/claude-session.sh
chmod +x /root/bin/claude-session.sh

echo "node $(node --version), npm $(npm --version)"
echo "claude code: $(claude --version 2>/dev/null || echo 'installed -- not logged in yet')"
