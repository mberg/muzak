---
name: muzak
description: >
  Use whenever the user wants to control Sonos speakers, play music in a room,
  search or play Spotify, build or edit Spotify playlists, manage their Spotify
  library, group/ungroup rooms, save scenes, or generally do anything with music
  on local speakers — even if they don't name "Sonos" or "Spotify" explicitly
  (phrases like "play X in the kitchen", "queue this song", "make a playlist",
  "what's playing", "turn it down", "move the music to the office" all qualify).
  Combines two CLIs — `sonos` (sonoscli, local Sonos control over UPnP) and
  `spogo` (Spotify power CLI via browser cookies). Use them together — spogo
  finds and manages content on Spotify, sonos plays it on actual rooms.
---

# muzak — Sonos + Spotify from the terminal

You have two installed CLIs that compose well:

- **`sonos`** (sonoscli) — controls Sonos speakers on the local network. No cloud. Discovers rooms, plays/pauses, groups speakers, manages the Sonos queue, saves scenes. Talks UPnP/SOAP directly to speakers.
- **`spogo`** — Spotify CLI authenticated via the cookies your browser already has (no API key registration). Search the catalog, manage playlists, manage saved library, list/transfer Connect devices, drive Spotify playback.

They share a vocabulary: **Spotify URIs** (`spotify:track:ID`, `spotify:album:ID`, `spotify:playlist:ID`) and `https://open.spotify.com/...` URLs are accepted by both. That's the seam — spogo *finds and manages*, sonos *plays in rooms*.

## When to reach for which tool

| Goal | Tool | Why |
|------|------|-----|
| Play something in a Sonos room | `sonos open --name "Room" <uri-or-url>` | sonos owns "where it plays" |
| Just search Spotify (catalog lookup, get URIs) | `spogo search <type> <query> --json` | No SMAPI auth needed; richer JSON |
| Search Spotify *and* play on Sonos in one shot | `sonos play spotify "<query>" --name "Room"` | SMAPI shortcut — no Spotify creds, no cookies |
| Create / edit / delete Spotify playlists | `spogo playlist ...` | sonos can't write to Spotify |
| List or modify saved library (tracks/albums/artists) | `spogo library ...` | Same reason |
| Group / ungroup / party-mode speakers | `sonos group ...` | spogo has no concept of rooms |
| Save / restore room layout + volumes | `sonos scene ...` | sonos-only |
| Set volume on a specific room | `sonos volume set --name "Room" 25` | 0–100 scale |
| See what's playing on Sonos | `sonos status --name "Room"` | Reports coordinator state |
| Transfer Spotify Connect playback to a phone/laptop (not Sonos) | `spogo device set <name>` then `spogo play` | Sonos rooms aren't Connect devices in the normal sense |
| Build a playlist from a search and play it on Sonos | spogo to build → `sonos open` the playlist URI | Composition |

If both could do something (e.g. searching Spotify), prefer the tool that fits the larger task: if the next step is "play on Sonos", `sonos play spotify` or `sonos open` is one fewer step. If the next step is "save to a playlist", stay in spogo.

## The composition pattern (the whole point)

The most powerful uses combine the two through Spotify URIs. Pipeline shape:

```bash
# 1. spogo finds → emits a URI
URI=$(spogo search track "miles davis kind of blue" --json | jq -r '.items[0].uri')

# 2. sonos plays it in a specific room
sonos open --name "Kitchen" "$URI"
```

Or build a playlist on the Spotify side and play the whole thing on Sonos:

```bash
PLAYLIST=$(spogo playlist create "Friday vibes" --json | jq -r '.uri')
spogo playlist add "$PLAYLIST" \
  $(spogo search track "khruangbin" --json | jq -r '.items[0:3][].uri')
sonos open --name "Living Room" "$PLAYLIST"
```

Use `--json` on spogo and `--format json` on sonos (different flags — easy mistake) so output is parseable.

## Discover what's there before guessing

Don't invent room names. Run:

```bash
sonos discover                     # lists actual rooms on the network
sonos config get                   # see saved defaults (defaultRoom, etc.)
```

If the user already set `defaultRoom`, `--name` is optional and you can omit it.

For Spotify, check auth before the first call in a session:

```bash
spogo auth status
```

If it says no cookies / expired, the user needs to run `spogo auth import` (reads from their browser) or `spogo auth paste` (manual cookie paste). You can't auth for them.

## Authentication, briefly

- **spogo** — browser cookies. `spogo auth import` reads from Chrome/Safari/Firefox. Falls back to `spogo auth paste` if keychain access fails (this is common on macOS — the user pastes cookie values from devtools).
- **sonos for Spotify via SMAPI** (`sonos play spotify`, `sonos smapi search`) — needs a one-time `sonos auth smapi begin` / `sonos auth smapi complete` flow per service. No Spotify account API keys.
- **sonos for Spotify Web API search** (`sonos search spotify`) — needs `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` env vars (a registered Spotify dev app). Most users won't have this; prefer `spogo search` or `sonos smapi search` instead.

If a command fails with auth-looking output, check which auth path it uses and tell the user the exact next command to run.

## Idiomatic recipes

**Play X in a room — fastest path:**
```bash
sonos play spotify "tycho awake" --name "Office"
```
One call. Uses SMAPI under the hood (needs SMAPI Spotify linked).

**Play a specific URL the user pasted:**
```bash
sonos open --name "Kitchen" "https://open.spotify.com/track/6NmXV4o6bmp704aPGyTVVG"
```
`open` accepts URIs *or* `open.spotify.com` URLs. Use this for user-supplied links.

**Queue without starting:**
```bash
sonos enqueue --name "Kitchen" "<uri>"          # just queue
sonos enqueue --next --name "Kitchen" "<uri>"   # queue as up-next (shuffle mode)
```

**Search and pick a non-top result:**
```bash
spogo search track "blue in green" --limit 5 --json | jq '.items[] | {name, artist: .artists[0].name, uri}'
# user picks one → sonos open --name "Kitchen" <uri>
```

**Whole-house party:**
```bash
sonos group party --to "Living Room"   # joins everything to Living Room's group
sonos volume set --name "Living Room" 30
```
And to undo: `sonos group dissolve --name "Living Room"`.

**Save current room layout, do something, restore:**
```bash
sonos scene save before-dinner
# ... regroup, change volumes ...
sonos scene apply before-dinner
```

**Move what's playing to another room:**
There's no single "move" command. Pattern: read state from old room, group new room with old, then unjoin old.
```bash
sonos group join --name "Office" --to "Kitchen"     # Office joins Kitchen's group
sonos group unjoin --name "Kitchen"                  # Kitchen leaves; Office keeps playing
```

**Build a playlist from a search:**
```bash
PL=$(spogo playlist create "Focus" --json | jq -r '.id')
spogo search track "ambient piano" --limit 10 --json \
  | jq -r '.items[].uri' \
  | xargs spogo playlist add "$PL"
sonos open --name "Office" "spotify:playlist:$PL"
```

## Gotchas and things to know

- **Two different JSON flags.** `sonos --format json` vs `spogo --json`. Mixing them up gives plain text and breaks pipelines.
- **Volume scale.** sonos uses 0–100. Don't pass 0.5 or 50%.
- **Room names with spaces** must be quoted: `--name "Living Room"`, not `--name Living Room`.
- **Coordinator awareness.** When rooms are grouped, playback commands go to the group's coordinator. `sonos status --name "Bedroom"` may show what's playing on the group, not Bedroom alone. `sonos group status` shows the topology.
- **`play-url` ≠ `open`.** `sonos open` is for Spotify items via the linked Sonos service. `sonos play-url` runs a local proxy and pipes arbitrary web audio (YouTube, etc.) through it. Use `play-url` for non-Spotify URLs and `open`/`play spotify` for Spotify.
- **spogo `play` controls Spotify Connect**, not Sonos. `spogo play <track>` plays on the user's *currently active Spotify device* (their phone, laptop). To play on Sonos use `sonos`. Don't conflate them.
- **Cookie auth can expire.** If spogo starts erroring, re-run `spogo auth status`; the user may need to re-import.
- **Don't mass-modify library/playlists without confirming.** Adding 3 tracks: fine. Removing all saved tracks, deleting playlists: confirm first. These are destructive on a shared external account.
- **Discovery is fast but not free.** Per call. If running many commands in a script, set `--ip` or `sonos config set defaultRoom "..."` to skip discovery.

## Output formats

- For human display: default plain output is fine.
- For piping/parsing: `--format json` (sonos) / `--json` (spogo). Both expose stable schemas.
- For spreadsheet-ish: `sonos --format tsv`.

When you read JSON output, prefer `jq` for extracting fields. URIs live at `.uri` on spogo items; sonos JSON shapes vary by command (use `--format json` and inspect once).

## Reference

For an exhaustive list of every command and flag in both tools, see `references/commands.md`. Read it when the user asks for something the recipes above don't cover, or when you need a flag you don't remember.
