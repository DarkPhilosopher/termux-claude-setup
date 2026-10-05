#!/data/data/com.termux/files/usr/bin/bash
# Shows/refreshes the ongoing (non-dismissible) Claude control notification,
# with buttons that reflect the current voice-loop state.
DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$DIR/state"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo off)

if [ "$STATE" = "on" ]; then
  TITLE="Claude Voice: ON"
  CONTENT="Listening continuously - tap to stop"
  BTN1="Stop Voice"
else
  TITLE="Claude Control"
  CONTENT="Voice off - tap to start"
  BTN1="Start Voice"
fi

if termux-notification \
  --id claude-control \
  --ongoing \
  --title "$TITLE" \
  --content "$CONTENT" \
  --button1 "$BTN1" \
  --button1-action "$DIR/toggle.sh" \
  --button2 "Ensure Claude Running" \
  --button2-action "proot-distro login ubuntu -- /root/bin/claude-session.sh"
then
  # Visible, on-screen confirmation that this actually posted (and as
  # pinned/--ongoing specifically) -- termux-notification succeeding
  # doesn't by itself prove anything showed up, so this is a second,
  # independent signal you can actually see rather than just trust.
  termux-toast "Claude Control pinned"
  echo "$(date '+%F %T') posted --ongoing, title: $TITLE" >> "$DIR/notify.log"
else
  termux-toast "Claude Control notification FAILED to post"
  echo "$(date '+%F %T') FAILED to post" >> "$DIR/notify.log"
fi
