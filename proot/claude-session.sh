#!/bin/bash
# Ensures a tmux session named "claude" is running Claude Code inside this
# Ubuntu proot container. Safe to call repeatedly (idempotent).
SOCK=/tmp/tmux-claude.sock

if ! tmux -S "$SOCK" has-session -t claude 2>/dev/null; then
  tmux -S "$SOCK" new-session -d -s claude "claude"
fi
