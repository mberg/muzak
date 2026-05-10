# Full command reference

This is the long-form reference for both CLIs. SKILL.md covers the common patterns; come here for exhaustive flags or commands not covered there.

## Table of contents

- [sonos (sonoscli) global flags](#sonos-global-flags)
- [sonos commands](#sonos-commands)
  - Discovery & status: `discover`, `status`, `watch`
  - Playback: `play`, `pause`, `stop`, `next`, `prev`, `play-url`, `play-uri`, `play youtube`, `linein`, `tv`
  - Volume & mute: `volume`, `mute`
  - Grouping: `group`
  - Queue: `queue`
  - Favorites & scenes: `favorites`, `scene`
  - Spotify / SMAPI: `open`, `enqueue`, `play spotify`, `search spotify`, `smapi`, `auth smapi`
  - Local config: `config`
- [spogo global flags](#spogo-global-flags)
- [spogo commands](#spogo-commands)
  - Auth, search, info
  - Playback (Spotify Connect)
  - Queue, library, playlist, devices

---

## sonos global flags

Apply to every `sonos` command:

| Flag | Default | Purpose |
|------|---------|---------|
| `--name <string>` | — | Target speaker by friendly name (e.g. `"Kitchen"`) |
| `--ip <string>` | — | Target speaker by IP (skips SSDP discovery — much faster) |
| `--format <plain\|json\|tsv>` | `plain` | Output format |
| `--timeout <duration>` | `15s` | Discovery + per-call timeout |
| `--debug` | off | Print SOAP traces to stderr |

A speaker target (`--name` or `--ip`) is required for most playback/volume/queue commands. If `defaultRoom` is set in config, it's used when neither is supplied.

## sonos commands

### Discovery & status

- `sonos discover [--all]` — SSDP M-SEARCH for speakers. `--all` includes invisible/bonded devices.
- `sonos status` (alias `sonos now`) — Coordinator transport state, current track, volume, mute. Parses TrackMetaData when available.
- `sonos watch` — Subscribe to live UPnP events on the speaker. Streams updates.

### Playback

- `sonos play` — Resume playback on the coordinator.
- `sonos play spotify <query>` — SMAPI search + play top result (or use `--index N`). Flags: `--service "Spotify"` (default), `--category tracks|albums|playlists` (default tracks), `--enqueue` (don't auto-start), `--title <override>`.
- `sonos play youtube <url>` — Plays a YouTube URL via yt-dlp + local proxy.
- `sonos pause` / `sonos stop`
- `sonos next` / `sonos prev`
- `sonos play-url <url>` — Stream arbitrary web audio through a local MP3 proxy. Auto-detects YT/YT-Music playlist URLs. Notable flags: `--bitrate 192k`, `--playlist`/`--no-playlist`, `--playlist-limit N`, `--port N`, `--resolver auto|direct|yt-dlp`, `--title <override>`.
- `sonos play-uri <uri>` — Play an arbitrary URI (advanced; bypasses helpful resolution).
- `sonos linein` — Switch to line-in.
- `sonos tv` — Switch to TV input.

### Volume & mute

- `sonos volume get` / `sonos volume set <0-100>` — RenderingControl on the coordinator.
- `sonos mute` (with subcommands per speaker / group)

### Grouping

`sonos group <subcommand>`:
- `status` — Show current groups and members.
- `join --to "<other-room>"` — Join another group.
- `unjoin` — Leave the current group.
- `dissolve` — Ungroup all members of the group.
- `party --to "<room>"` — Join *all* speakers to the target group. (House party.)
- `solo` — Make this room play by itself.
- `volume` / `mute` — Group-wide volume / mute.

### Queue

`sonos queue <subcommand>`:
- `list` — List queue entries (1-based positions).
- `play <N>` — Play queue entry N.
- `remove <N>` — Remove entry N.
- `clear` — Clear the queue.

### Favorites & scenes

- `sonos favorites` — Browse and play Sonos Favorites.
- `sonos scene save <name>` — Capture grouping + per-room volume/mute.
- `sonos scene apply <name>` — Restore.
- `sonos scene list` / `sonos scene delete <name>`.

### Spotify / SMAPI

- `sonos open <spotify-uri-or-link>` — Enqueue + start playback. Flags: `--next` (queue as up-next), `--title <display>`. Accepts `spotify:track:ID`, `spotify:album:ID`, `spotify:playlist:ID`, and `https://open.spotify.com/...` URLs.
- `sonos enqueue <spotify-uri-or-link>` — Same shape, but no auto-play. Flags: `--next`, `--title`.
- `sonos search spotify <query>` — Spotify **Web API** search (needs `SPOTIFY_CLIENT_ID`/`SPOTIFY_CLIENT_SECRET`). Flags: `--type track|album|playlist|show|episode`, `--market US`, `--limit 1-50`, `--index N`, `--open` / `--enqueue` (act on selected result, requires `--name`/`--ip`).
- `sonos smapi services` — List linked services.
- `sonos smapi categories --service "Spotify"` — Show search categories.
- `sonos smapi search <query>` — Search a linked service (Spotify et al.) **without** Web API creds. Flags: `--service "Spotify"`, `--category tracks|albums|artists|playlists`, `--limit`, `--index`, `--open`/`--enqueue`.
- `sonos smapi browse <container>` — Browse a service container via getMetadata.
- `sonos auth smapi begin` — Start DeviceLink/AppLink for a service.
- `sonos auth smapi complete` — Finish linking and store tokens.

### Local config

`sonos config <subcommand>`. Stores defaults in `~/.config/sonoscli/config.json`.
- `get` / `get <key>` / `set <key> <value>` / `unset <key>` / `path`.
- Useful keys: `defaultRoom`, `defaultTimeout`.

---

## spogo global flags

Apply to every `spogo` command. Each also has a corresponding `SPOGO_<NAME>` env var.

| Flag | Default | Purpose |
|------|---------|---------|
| `--config <path>` | — | Config file path |
| `--profile <name>` | — | Named profile (multi-account) |
| `--timeout <dur>` | `10s` | HTTP timeout |
| `--market <CC>` | — | Market country code |
| `--language <locale>` | — | Locale |
| `--device <name\|id>` | — | Active Connect device |
| `--engine <auto\|web\|connect\|applescript>` | `auto` | Playback engine |
| `--json` | off | JSON output |
| `--plain` | off | Plain output (no colors) |
| `--no-color` | off | Disable color |
| `-q --quiet` / `-v --verbose` / `-d --debug` | | Logging |
| `--no-input` | off | Disable interactive prompts |

Exit codes: `0` ok, `2` invalid usage, `3` auth failure, `4` network.

## spogo commands

### Auth

- `spogo auth status` — Show cookie status.
- `spogo auth import` — Read cookies from an installed browser (Chrome/Safari/Firefox).
- `spogo auth paste` — Paste cookie values manually (fallback when keychain reads fail).
- `spogo auth clear` — Wipe stored cookies.

### Search

`spogo search <type> <query> [--limit N] [--offset N]`. Types: `track`, `album`, `artist`, `playlist`, `show`, `episode`.

### Info lookup

- `spogo track info <id|uri|url>`
- `spogo album info <id|uri|url>`
- `spogo artist info <id|uri|url>`
- `spogo playlist info <id|uri|url>`
- `spogo show info <id|uri|url>`
- `spogo episode info <id|uri|url>`

### Playback (Spotify Connect)

These drive Spotify Connect / web / AppleScript — **not** Sonos. They affect whatever Spotify device is currently active for the user (typically phone, laptop, or a SpotifyConnect-enabled speaker).

- `spogo play [<item>] [--shuffle] [--type track|album|playlist|show|episode]`
- `spogo pause`
- `spogo next` / `spogo prev`
- `spogo seek <position>`
- `spogo volume <level>`
- `spogo shuffle <state>`
- `spogo repeat <mode>`
- `spogo status`

### Queue

- `spogo queue add <item>`
- `spogo queue show`
- `spogo queue clear` (if supported)

### Library

- `spogo library tracks list [--limit N] [--offset N]`
- `spogo library tracks add <ids...>` / `spogo library tracks remove <ids...>`
- `spogo library albums list / add / remove`
- `spogo library artists list / follow / unfollow`
- `spogo library playlists list`

### Playlists (mutation)

- `spogo playlist create <name> [--public] [--collab]`
- `spogo playlist add <playlist> <tracks...>`
- `spogo playlist remove <playlist> <tracks...>`
- `spogo playlist tracks <playlist> [--limit N] [--offset N]`

### Devices

- `spogo device list` — List available Spotify Connect devices.
- `spogo device set <name|id>` — Transfer playback to a device.

---

## Cross-tool URI / URL formats

Both tools accept the same Spotify identifiers:

- URI: `spotify:track:6NmXV4o6bmp704aPGyTVVG`, `spotify:album:...`, `spotify:playlist:...`
- URL: `https://open.spotify.com/track/6NmXV4o6bmp704aPGyTVVG[?si=...]`
- Bare ID: 22-char base62 (use `--type` on spogo to disambiguate)

So you can take output from `spogo search track --json | jq -r '.items[0].uri'` and feed it directly to `sonos open --name "Room"`.
