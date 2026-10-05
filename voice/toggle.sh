#!/data/data/com.termux/files/usr/bin/bash
# Flips the voice-loop on/off, starting or killing the background listener,
# then refreshes the notification buttons to match.
DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$DIR/state"
PID_FILE="$DIR/loop.pid"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo off)

if [ "$STATE" = "on" ]; then
  echo off > "$STATE_FILE"
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
  fi
  termux-toast "Voice off"
else
  echo on > "$STATE_FILE"
  nohup "$DIR/loop.sh" >> "$DIR/loop.log" 2>&1 &
  echo $! > "$PID_FILE"
  termux-toast "Voice on - listening"
fi

"$DIR/notify.sh"
