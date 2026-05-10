# muzak

A Claude Code skill that teaches Claude how to drive your Sonos speakers and Spotify from the terminal, using two CLIs together:

- **[sonoscli](https://sonoscli.sh)** (`sonos`) — local Sonos control over UPnP. Discover rooms, play/pause, group, queue, scenes.
- **[spogo](https://spogo.sh)** (`spogo`) — Spotify CLI authenticated via your browser cookies. Search, library, playlists, devices.

The skill explains when to reach for which tool, how to compose them through Spotify URIs, and the gotchas (different `--json` vs `--format json` flags, group coordinator semantics, auth paths, etc.).

## Install

### As a Claude Code plugin (recommended)

This repo doubles as a Claude Code plugin marketplace. Inside Claude Code:

```
/plugin marketplace add mberg/muzak
/plugin install muzak@muzak
```

Then `/reload-plugins` and you're set. The skill activates automatically when you mention music, speakers, or Spotify.

To update later:

```
/plugin marketplace update muzak
/plugin install muzak@muzak
```

### Bare install (no plugin system)

One-liner that drops the skill into `~/.claude/skills/muzak/` and checks for the two CLI deps:

```bash
curl -fsSL https://raw.githubusercontent.com/mberg/muzak/main/install.sh | bash
```

Or with `git`:

```bash
git clone https://github.com/mberg/muzak.git
cp -R muzak/skills/muzak ~/.claude/skills/muzak
```

Then restart Claude Code (or run `/reload-skills`).

### Prerequisites

```bash
brew install steipete/tap/sonoscli
brew install steipete/tap/spogo
```

The bare installer prints these for you if either is missing.

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

You only need one working. The skill prefers spogo's cookie auth since it's the lowest friction.

## What's in the repo

```
muzak/
├── .claude-plugin/
│   ├── marketplace.json    plugin marketplace listing
│   └── plugin.json          plugin metadata
├── skills/
│   └── muzak/
│       ├── SKILL.md         the guide Claude reads
│       └── references/
│           └── commands.md  full flag reference for both CLIs
├── install.sh               bare-install fallback
└── README.md
```

## Uninstall

```
/plugin uninstall muzak@muzak
/plugin marketplace remove muzak
```

Or for the bare install: `rm -rf ~/.claude/skills/muzak`.

## License

MIT
