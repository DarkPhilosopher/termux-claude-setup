#!/data/data/com.termux/files/usr/bin/bash
# Termux:Boot entry point - runs automatically after every reboot.

# Bring up the Claude Code tmux session inside the Ubuntu container.
proot-distro login ubuntu -- /root/bin/claude-session.sh

# Start with voice off. Run ~/.termux-voice/toggle.sh by hand to turn it
# on, or ~/.termux-voice/notify.sh to post the control notification.
echo off > /data/data/com.termux/files/home/.termux-voice/state

# Watch free memory for the rest of however long this boot lasts -- more
# than one `claude` process running at once can force this phone into
# heavy swap and freeze Termux. Runs forever on its own; nothing here
# needs to stop it. nohup+disown so it survives this boot script's own exit.
nohup /data/data/com.termux/files/home/bin/memguard.sh >> "$HOME/.memguard.log" 2>&1 &
disown
