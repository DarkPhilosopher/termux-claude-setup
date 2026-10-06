#!/usr/bin/env python3
"""Runs `csync push` on a timer, forever, so conversation history and
memory reach GitHub without needing to remember to run `cl`/`csync` by
hand. Same shape as ~/bin/memguard.sh: loop, sleep, log, no toggle
needed for a pure background watcher.

    csync-auto.py                   push every 5 minutes (default)
    csync-auto.py --interval 600    push every 10 minutes instead

Started by claude-session.sh (nohup + disown, so it survives whatever
started it exiting) -- not meant to be run by hand, but safe to:
re-running it just means two loops both trying to push, and csync
itself already handles "nothing changed" (an empty commit is skipped)
and "push failed, offline" (logged, tried again next tick) cleanly.
"""
import argparse
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

CSYNC = Path.home() / ".claude" / "bin" / "csync"
LOG = Path.home() / ".claude" / "csync-auto.log"
DEFAULT_INTERVAL = 300  # 5 minutes -- frequent enough to not lose much


def log(line):
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with LOG.open("a") as f:
        f.write("%s  %s\n" % (stamp, line))


def push_once():
    result = subprocess.run([str(CSYNC), "push"], capture_output=True, text=True)
    out = (result.stdout + result.stderr).strip()
    log(out if out else "(nothing to push)")


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--interval", type=int, default=DEFAULT_INTERVAL,
                   help="seconds between pushes (default %d)" % DEFAULT_INTERVAL)
    args = p.parse_args()

    if not CSYNC.exists():
        sys.exit("csync not found at %s -- run setup-claude-sync.py first" % CSYNC)

    log("csync-auto starting, pushing every %ds" % args.interval)
    while True:
        try:
            push_once()
        except Exception as err:                                  # noqa: BLE001
            log("error: %s" % err)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
