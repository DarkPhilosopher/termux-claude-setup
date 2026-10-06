#!/usr/bin/env python3
"""Wire a phone's ~/.claude up to the shared claude-sync GitHub repo, the
same way it was done by hand on the A17 (2026-10-05): ~/.claude itself
becomes a git repo, tracking only conversations/memory/prompt-history/
settings (never .credentials.json -- each phone logs into Claude on its
own), and cl/csync get put on PATH.

Safe to run on:
  - a BRAND NEW phone with no ~/.claude history yet (the common case
    setup-claude-code.sh hands off to) -- just clones claude-sync in.
  - a phone that already has real ~/.claude history of its own (like the
    A17 did) -- inits a repo there, then MERGES with whatever's already
    on claude-sync rather than overwriting either side
    (--allow-unrelated-histories, -X ours so this phone's own history
    wins on the two small shared files, history.jsonl/settings.json --
    actual conversations never collide, they're one file per session).
  - a phone that's already been run through this once -- detects the
    existing setup and does nothing.

    python3 setup-claude-sync.py

Needs `gh auth login` done first (interactively -- this never handles
credentials itself).
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
REPO_URL = "https://github.com/DarkPhilosopher/claude-sync.git"

GITIGNORE = """\
# Whitelist: only sync conversations, memory, prompt history, settings.
# Never sync .credentials.json (each phone logs in on its own).
/*
!/.gitignore
!/projects/
!/history.jsonl
!/settings.json
!/CLAUDE.md
!/bin/
"""


def run(*args, cwd=CLAUDE_DIR, check=True, capture=True):
    result = subprocess.run(args, cwd=cwd, capture_output=capture, text=True)
    if check and result.returncode != 0:
        raise RuntimeError("%s failed:\n%s" % (" ".join(args), result.stderr))
    return result.stdout.strip() if capture else ""


def have_gh_auth():
    return subprocess.run(["gh", "auth", "status"], capture_output=True).returncode == 0


def is_git_repo(path):
    return subprocess.run(["git", "-C", str(path), "rev-parse", "--git-dir"],
                           capture_output=True).returncode == 0


def unnest_any_memory_git():
    """If memory/ (or any project subfolder) was ever its own separate repo
    -- like the A17's own claude-memory clone was -- fold it in rather than
    leaving a submodule-shaped landmine `git add -A` would silently skip."""
    for git_dir in CLAUDE_DIR.glob("projects/*/*/.git"):
        folder = git_dir.parent
        status = subprocess.run(["git", "-C", str(folder), "status", "--short"],
                                 capture_output=True, text=True)
        if status.stdout.strip():
            print("  %s has uncommitted changes of its own -- leaving its "
                  ".git alone, not folding it in" % folder)
            continue
        shutil.rmtree(git_dir)
        print("  folded %s's own git history into this one" % folder)


def start_csync_auto():
    """Launches csync-auto.py in the background right now, same idempotent
    "already running?" check claude-session.sh itself uses at boot -- so
    auto-push starts immediately after setup instead of waiting for the
    next reboot or session-ensure call."""
    script = CLAUDE_DIR / "bin" / "csync-auto.py"
    if not script.exists():
        return
    already = subprocess.run(["pgrep", "-f", "csync-auto.py"], capture_output=True)
    if already.returncode == 0:
        return
    log = CLAUDE_DIR / "csync-auto.log"
    with log.open("a") as f:
        subprocess.Popen(["python3", str(script)], stdout=f, stderr=f,
                          start_new_session=True)


def write_bin_scripts():
    bin_dir = CLAUDE_DIR / "bin"
    bin_dir.mkdir(exist_ok=True)
    here = Path(__file__).resolve().parent
    for name in ("cl", "csync", "csync-auto.py"):
        src = here / name
        if src.exists():
            shutil.copy(src, bin_dir / name)
            (bin_dir / name).chmod(0o755)


def main():
    if not have_gh_auth():
        sys.exit("Not logged into gh yet -- run `gh auth login` first, "
                  "then run this again.")

    if is_git_repo(CLAUDE_DIR):
        remotes = run("git", "remote", "-v")
        if "claude-sync" in remotes:
            print("Already set up -- ~/.claude is already tracking claude-sync.")
            run("git", "pull", "-q", check=False)
            write_bin_scripts()  # pick up a newer csync-auto.py if one shipped
            start_csync_auto()
            print("Pulled the latest. Use `cl` to continue your last chat.")
            return
        sys.exit("~/.claude is a git repo already, but not pointed at "
                  "claude-sync -- something else is going on here, stopping "
                  "rather than guessing.")

    print("== setting up ~/.claude as a git repo ==")
    (CLAUDE_DIR / ".gitignore").write_text(GITIGNORE)
    unnest_any_memory_git()
    write_bin_scripts()

    run("git", "init", "-q")
    user_id = run("gh", "api", "user", "--jq", ".id")
    run("git", "config", "user.name", "DarkPhilosopher")
    run("git", "config", "user.email",
        "%s+DarkPhilosopher@users.noreply.github.com" % user_id)
    run("gh", "auth", "setup-git", capture=False)

    has_history = any(CLAUDE_DIR.glob("projects/*/*.jsonl"))
    run("git", "add", "-A")
    run("git", "commit", "-q", "-m",
        "Initial sync -- %s" % ("existing history" if has_history else "fresh phone"))

    run("git", "remote", "add", "origin", REPO_URL)
    remote_had_commits = True
    try:
        run("git", "fetch", "origin")
    except RuntimeError:
        remote_had_commits = False

    run("git", "branch", "-M", "main")
    if remote_had_commits:
        print("== merging with what's already on claude-sync ==")
        try:
            run("git", "merge", "origin/main", "--allow-unrelated-histories",
                "-X", "ours", "-q", "-m", "Merge with existing claude-sync history")
        except RuntimeError as err:
            sys.exit("Merge hit something unexpected, stopping rather than "
                      "guessing:\n%s\nFix it by hand in %s, then re-run." %
                      (err, CLAUDE_DIR))
    run("git", "push", "-q", "-u", "origin", "main")

    for name in ("cl", "csync"):
        link = Path("/usr/local/bin") / name
        try:
            if link.exists() or link.is_symlink():
                link.unlink()
            link.symlink_to(CLAUDE_DIR / "bin" / name)
        except OSError as err:
            print("  couldn't link %s onto PATH (%s) -- run it as "
                  "~/.claude/bin/%s instead" % (name, err, name))

    start_csync_auto()

    print()
    print("Done. ~/.claude is now synced via claude-sync (private repo).")
    print("Use:  cl        continue your last chat, pulling/pushing automatically")
    print("      cl -r     pick a chat")
    print("      csync pull / csync push   the sync step on its own")
    print("      csync-auto.py is now running in the background too --")
    print("      pushes on its own timer, no need to remember any of the above.")


if __name__ == "__main__":
    main()
