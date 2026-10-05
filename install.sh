#!/data/data/com.termux/files/usr/bin/bash
# Sets up a phone to run Claude Code in Termux the same way the A17 does:
# Claude Code itself lives inside an Ubuntu proot-distro container (not
# bare Termux), auto-starts on every boot via Termux:Boot, and can
# optionally be driven by voice. Run this from a fresh Termux:
#
#     bash install.sh
#
# What this script does NOT do -- real steps only you can do by hand:
#   1. Install the Termux, Termux:API, and Termux:Boot apps, if they
#      aren't already -- all from the SAME source (e.g. all F-Droid).
#      Android enforces matching signing keys between a plugin and the
#      Termux it's plugging into; mismatched sources make Termux:API
#      calls fail silently.
#   2. Grant Termux whatever permissions it asks for the first time
#      notifications/microphone/storage come up.
#   3. Open the Termux:Boot app itself at least once -- its boot
#      receiver doesn't register with Android until it has been.
#   4. After this script finishes, log in: see what it prints at the end.
#   5. Reboot once, to prove the boot-persistence path actually works.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== termux packages =="
pkg install -y proot-distro termux-api git

echo "== storage access =="
termux-setup-storage

echo "== termux.properties: allow-external-apps =="
mkdir -p "$HOME/.termux"
PROPS="$HOME/.termux/termux.properties"
if ! grep -q "^allow-external-apps" "$PROPS" 2>/dev/null; then
    echo "allow-external-apps = true" >> "$PROPS"
fi
termux-reload-settings || true

echo "== boot script =="
mkdir -p "$HOME/.termux/boot"
cp "$HERE/boot/start-claude.sh" "$HOME/.termux/boot/start-claude.sh"
chmod +x "$HOME/.termux/boot/start-claude.sh"

echo "== voice control =="
mkdir -p "$HOME/.termux-voice"
cp "$HERE"/voice/*.sh "$HOME/.termux-voice/"
chmod +x "$HOME"/.termux-voice/*.sh
echo off > "$HOME/.termux-voice/state"

echo "== claude() guard in .bashrc =="
if ! grep -q "proot-distro login ubuntu.*-- claude" "$HOME/.bashrc" 2>/dev/null; then
    cat "$HERE/bashrc-claude-guard.sh" >> "$HOME/.bashrc"
    echo "added -- 'source ~/.bashrc' or restart Termux to use it"
else
    echo "already present, left alone"
fi

echo "== ubuntu container =="
if ! proot-distro list 2>/dev/null | grep -qi "ubuntu.*installed"; then
    proot-distro install ubuntu
else
    echo "already installed"
fi

echo "== node + claude code inside the container =="
# Bind-mounting this repo's own folder in (read-only isn't an option
# proot-distro exposes, but nothing here writes back to it) so the
# in-container script can be run as a plain file, no quoting gymnastics
# passing a whole script through `bash -c "..."`.
proot-distro login ubuntu --bind "$HERE":/termux-claude-setup -- \
    bash /termux-claude-setup/proot/setup-claude-code.sh

echo
echo "=================================================================="
echo "Scriptable part done. Left to do by hand, in order:"
echo "  1. If Claude Code isn't logged in yet:"
echo "       proot-distro login ubuntu -- claude"
echo "     and follow its own login flow (this is tied to your account,"
echo "     nothing here can or should do it for you)."
echo "  2. Make sure the Termux:Boot app has been opened at least once."
echo "  3. Reboot the phone once, then check 'claude' is running:"
echo "       proot-distro login ubuntu -- tmux -S /tmp/tmux-claude.sock attach -t claude"
echo "=================================================================="
