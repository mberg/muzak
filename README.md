# muzak

A Claude Code skill that teaches Claude how to drive your Sonos speakers and Spotify from the terminal, using two CLIs together:

- **[sonoscli](https://sonoscli.sh)** (`sonos`) — local Sonos control over UPnP. Discover rooms, play/pause, group, queue, scenes.
- **[spogo](https://spogo.sh)** (`spogo`) — Spotify CLI authenticated via your browser cookies. Search, library, playlists, devices.

The skill explains when to reach for which tool, how to compose them through Spotify URIs, and the gotchas (different `--json` vs `--format json` flags, group coordinator semantics, auth paths, etc.).

## Install

One-liner — downloads the skill into `~/.claude/skills/muzak/` and checks for the two CLI deps:

```bash
curl -fsSL https://raw.githubusercontent.com/mberg/muzak/main/install.sh | bash
```

Or with `git` if you prefer:

```bash
git clone https://github.com/mberg/muzak ~/.claude/skills/muzak
```

Then restart Claude Code (or run `/reload-skills`) to pick it up.

### Prerequisites

```bash
brew install steipete/tap/sonoscli
brew install steipete/tap/spogo
```

The installer prints these for you if either is missing.

## Usage

Once installed, the skill triggers automatically. Say things like:

- *"what's playing on all my sonos speakers right now?"*
- *"play some khruangbin in the office at volume 20"*
- *"search spotify for 5 chill instrumental tracks and queue them in the living room — don't auto-play"*
- *"group all my speakers and play this spotify link"*
- *"make a focus playlist with 10 ambient tracks"*

Claude will discover your rooms, pick the right tool, and run the commands.

## Spotify auth

spogo authenticates via browser cookies. First time:

```bash
spogo auth import          # reads from Chrome/Safari/Firefox
# or, if keychain access fails:
spogo auth paste           # paste cookie values from devtools
```

For the sonos-side Spotify integrations:

- `sonos play spotify` / `sonos smapi search` use SMAPI — run `sonos auth smapi begin` then `sonos auth smapi complete`.
- `sonos search spotify` uses the Spotify Web API — set `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET`.

You only need one of these working. The skill prefers spogo's cookie auth since it's the lowest friction.

## What's in the skill

- `SKILL.md` — the main guide Claude reads (decision tree, composition pattern, recipes, gotchas)
- `references/commands.md` — full flag reference for both CLIs

## Uninstall

```bash
rm -rf ~/.claude/skills/muzak
```

## License

MIT
