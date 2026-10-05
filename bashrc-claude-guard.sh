
# --- added by termux-claude-setup/install.sh ---
# Warns before starting a second Claude session -- more than one running
# at once can push this phone into heavy swap and freeze Termux itself.
# This only ever asks, never silently blocks -- and closing a session
# doesn't lose it, `claude --continue` picks any of them back up later.
claude() {
    local running
    # -x claude matches the actual claude process by its own name, however
    # it was launched -- catches both this alias's own interactive sessions
    # AND the one Termux:Boot starts automatically in a tmux session on
    # every reboot (~/.termux/boot/start-claude.sh).
    running=$(pgrep -x claude 2>/dev/null)
    if [ -n "$running" ]; then
        echo "A Claude session already looks like it's running."
        echo "Starting another can freeze this phone (each one is heavy) --"
        echo "closing one later won't lose it, --continue picks it back up."
        printf "Start another anyway? [y/N] "
        read -r ans
        case "$ans" in
            y|Y|yes|Yes) ;;
            *) echo "cancelled -- nothing started"; return 1 ;;
        esac
    fi
    proot-distro login ubuntu --bind /storage/emulated/0:/sdcard -- claude "$@"
}
