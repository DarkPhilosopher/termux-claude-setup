#!/data/data/com.termux/files/usr/bin/bash
# Continuous voice-capture loop: listens, transcribes, and sends the text
# into the "claude" tmux session inside the Ubuntu proot container --
# but ONLY when what's heard actually mentions "claude" (a wake word), so
# ordinary speech meant for some OTHER Termux session's own notification
# reply box doesn't leak into Claude's session too.
#
# Every phrase heard is logged to heard.log (timestamp + text + whether
# it was sent on or ignored), so there's a record of exactly what the
# mic picked up, regardless of which reply box it was actually meant for.
#
# Runs until $STATE_FILE no longer says "on".
DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$DIR/state"
HEARD_LOG="$DIR/heard.log"
SOCK=/tmp/tmux-claude.sock

while [ "$(cat "$STATE_FILE" 2>/dev/null)" = "on" ]; do
  TEXT=$(termux-speech-to-text 2>/dev/null)
  if [ -n "$TEXT" ]; then
    STAMP="$(date '+%F %T')"
    case "$(printf '%s' "$TEXT" | tr '[:upper:]' '[:lower:]')" in
      *claude*)
        echo "$STAMP  SENT    $TEXT" >> "$HEARD_LOG"
        termux-toast "Sent to Claude: $TEXT"
        proot-distro login ubuntu -- tmux -S "$SOCK" send-keys -t claude "$TEXT" Enter
        ;;
      *)
        echo "$STAMP  ignored $TEXT" >> "$HEARD_LOG"
        termux-toast "Heard (no 'claude', ignored): $TEXT"
        ;;
    esac
  fi
  sleep 1
done
