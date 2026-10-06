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
command -v gh >/dev/null 2>&1 || apt-get install -y gh

npm install -g @anthropic-ai/claude-code

mkdir -p /root/bin
cp "$(dirname "$0")/claude-session.sh" /root/bin/claude-session.sh
chmod +x /root/bin/claude-session.sh

# setup-claude-sync.py needs `gh auth login` done first, which can only
# happen interactively -- so it can't run as part of THIS script. Persist
# it (and cl/csync) into /root/bin instead of relying on install.sh's own
# bind mount, which only exists for this one invocation, so it's still
# reachable later with no repo folder needed.
mkdir -p /root/bin/claude-sync-setup
cp "$(dirname "$0")/setup-claude-sync.py" /root/bin/claude-sync-setup/
cp "$(dirname "$0")/cl" "$(dirname "$0")/csync" "$(dirname "$0")/csync-auto.py" /root/bin/claude-sync-setup/
chmod +x /root/bin/claude-sync-setup/*.py /root/bin/claude-sync-setup/cl /root/bin/claude-sync-setup/csync

echo "node $(node --version), npm $(npm --version)"
echo "claude code: $(claude --version 2>/dev/null || echo 'installed -- not logged in yet')"
