# termux-claude-setup

Everything needed to run Claude Code in Termux the way Gabe's A17 does
it, packaged so a second phone (the A33) is one script away instead of
retyping commands by hand. Claude Code itself runs **inside an Ubuntu
proot-distro container**, not bare Termux -- that's a deliberate,
already-working setup on the A17, reproduced here rather than changed.

## What you need to do by hand first

Android won't let a script do these — they need the actual UI:

1. Install **Termux**, **Termux:API**, and **Termux:Boot** — all from
   the *same* source (e.g. all F-Droid). A plugin app and the Termux it
   plugs into need matching signing keys, or Termux:API calls fail
   silently with no error.
2. Open the **Termux:Boot** app once. Its boot receiver doesn't
   register with Android until it's been opened at least one time.

## Then, in Termux

```
git clone https://github.com/DarkPhilosopher/termux-claude-setup.git
bash termux-claude-setup/install.sh
```

That installs `proot-distro`/`termux-api`/`git`, turns on
`allow-external-apps` in `termux.properties` (needed for Termux:API
intents, including the voice-control notification and
`RUN_COMMAND`-based tools), installs the Ubuntu container if it isn't
there yet, puts the boot script and voice-control scripts in place,
adds the `claude()` guard function to `.bashrc`, and installs Node +
Claude Code itself inside the container.

## What's left after that, by hand

1. **Log in.** This is the one step that's genuinely yours — it's tied
   to your account:
   ```
   proot-distro login ubuntu -- claude
   ```
   Follow its own login flow once; after that, every future `claude`
   session inside this container stays logged in.
2. **Share conversation history + memory with your other phone**, via
   the private [claude-sync](https://github.com/DarkPhilosopher/claude-sync)
   repo — also tied to your account, so also yours to run:
   ```
   proot-distro login ubuntu -- gh auth login
   proot-distro login ubuntu -- python3 /root/bin/claude-sync-setup/setup-claude-sync.py
   ```
   After that, `cl` (instead of plain `claude`) pulls the latest from
   your other phone, resumes your last chat, and pushes back on exit.
   Safe to run on a phone that already has its own real history too —
   it merges rather than overwrites (this phone's own history wins on
   the two small shared files, `history.jsonl`/`settings.json`; actual
   conversations never collide, each one is its own file).

   This step also starts `csync-auto.py` running in the background —
   pushes every 5 minutes on its own, so you don't have to remember
   `cl`/`csync` at all for your changes to reach GitHub. It's
   idempotent and started again at every boot alongside Claude Code
   itself, so there's nothing further to do here.
3. **Grant permissions** the first time Termux asks for them
   (notifications, microphone, storage).
4. **Reboot once**, to prove the boot-persistence path actually works.
   Check it came up:
   ```
   proot-distro login ubuntu -- tmux -S /tmp/tmux-claude.sock attach -t claude
   ```
   (Ctrl-B then D to detach without killing it.)

## What's in here

| File | What it does |
|---|---|
| `install.sh` | Run once, from real Termux. Does everything scriptable. |
| `boot/start-claude.sh` | Termux:Boot entry point — starts the `claude` tmux session inside the container, leaves voice off, starts `memguard.sh`. Gets copied to `~/.termux/boot/start-claude.sh`. |
| `voice/loop.sh`, `toggle.sh`, `notify.sh` | Optional: a pinned notification that toggles continuous speech-to-text, forwarding anything that mentions "claude" into the running session. Get copied to `~/.termux-voice/`. Off by default — run `~/.termux-voice/toggle.sh` to turn it on. |
| `bashrc-claude-guard.sh` | The `claude()` function `install.sh` appends to `.bashrc` — warns before starting a second session (more than one at once can push the phone into heavy swap and freeze Termux). |
| `proot/setup-claude-code.sh` | Runs *inside* the Ubuntu container — installs Node (NodeSource), `gh`, and `@anthropic-ai/claude-code`; writes `claude-session.sh` into `/root/bin/`, and `setup-claude-sync.py`/`cl`/`csync` into `/root/bin/claude-sync-setup/` for later. |
| `proot/claude-session.sh` | Idempotent — ensures a tmux session named `claude` is running Claude Code inside the container. What the boot script and the notification's "Ensure Claude Running" button both call. |
| `proot/setup-claude-sync.py` | Run by hand, after `gh auth login` — wires `~/.claude` up to the shared `claude-sync` repo (conversations, memory, prompt history, settings; never credentials). Merges rather than overwrites if this phone already has its own history. Idempotent. |
| `proot/cl`, `proot/csync` | The sync tools themselves, copied in by `setup-claude-sync.py`. `cl` = pull, `claude --continue` (or pass-through args), push. `csync pull`/`push` on their own. |
| `proot/csync-auto.py` | Runs `csync push` every 5 minutes, forever -- same shape as `memguard.sh`. Started by `setup-claude-sync.py` right away, and by `claude-session.sh` at every boot. |

## Why Termux:Boot starts a tmux session instead of `claude` directly

Termux:Boot runs each script once, briefly, at boot — it isn't a place
to leave a long-lived interactive process attached. `claude-session.sh`
starts Claude Code detached inside `tmux`, so it keeps running long
after the boot script itself has exited, and `proot-distro login ubuntu
-- tmux -S /tmp/tmux-claude.sock attach -t claude` reaches it any time
afterward.

## Memory, conversation history, and your other repos

`install.sh` only sets the *software* up. Step 2 above
(`setup-claude-sync.py`) is what actually carries over conversation
history and memory from your other phone, via
[claude-sync](https://github.com/DarkPhilosopher/claude-sync) (private).

Your actual Termux *programs* (`overseer`, `programs`, etc.) are a
separate thing, in a separate repo — `~/bin` →
[termux-bin](https://github.com/DarkPhilosopher/termux-bin). Once
Claude Code is running here, clone that one too to get the rest of
your toolkit.
