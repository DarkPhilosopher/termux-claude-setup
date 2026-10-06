#!/bin/bash
# Ensures a tmux session named "claude" is running Claude Code inside this
# Ubuntu proot container, and that csync-auto.py is pushing conversation
# history + memory to GitHub in the background. Safe to call repeatedly
# (idempotent) -- both checks are "is it already running" first.
SOCK=/tmp/tmux-claude.sock

if ! tmux -S "$SOCK" has-session -t claude 2>/dev/null; then
  tmux -S "$SOCK" new-session -d -s claude "claude"
fi

if [ -f "$HOME/.claude/bin/csync-auto.py" ] && ! pgrep -f "csync-auto.py" >/dev/null 2>&1; then
  nohup python3 "$HOME/.claude/bin/csync-auto.py" >> "$HOME/.claude/csync-auto.log" 2>&1 &
  disown
fi
