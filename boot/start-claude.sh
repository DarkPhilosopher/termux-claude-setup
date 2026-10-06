#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot entry point - runs automatically after every reboot.
#
# Hands off to `overseer boot` (~/bin/overseer, termux-bin repo) so the
# boot steps live under overseer with everything else. The steps below
# only run if overseer isn't installed on this phone yet.
if [ -f "$HOME/bin/overseer" ]; then
  exec python3 "$HOME/bin/overseer" boot
fi

# --- fallback: same steps overseer boot runs ---
proot-distro login ubuntu -- /root/bin/claude-session.sh
echo off > "$HOME/.termux-voice/state"
nohup "$HOME/bin/memguard.sh" >> "$HOME/.memguard.log" 2>&1 &
disown
