# GameSpice Emote

Godot 4.7+ addon for emotes, gestures, sprays, pings and map markers: a catalogue, a radial wheel model, server-validated equip and cooldowns. Part of the GameSpice addon family.

**The distributable is `addons/gs_emote/`.** It requires only gs-core (`addons/gs_core`, a gitignored symlink to `../../gs-core/addons/gs_core`). Never depend on another addon from here.

| Path | What it holds |
| --- | --- |
| `addons/gs_emote/gs_emote_api.gd` | `LEVEL` and `OLDEST`: the API level (1) and the oldest a consumer may target |
| `addons/gs_emote/core/`, `runtime/` | gs_emote_catalogue.gd, gs_emote_playback.gd (who is playing what, no clock), runtime/gs_emote_wheel_view.gd (draws a wheel), gs_emote_config.gd, gs_emote_gate.gd, gs_emote_wheel.gd (core is pure logic: no nodes, no I/O) |
| `cfg/addon/gs_emote/emote.yml` | shipped defaults, layered under the game, environment and command line |
| `examples/emote_selftest.gd` | the headless suite; `EXPECTED_SECTIONS` and `EXPECTED_CHECKS` must match what it runs |

## Boundaries

- Not art, audio or animation: a catalogue entry names a clip, spray or sound, it does not play one.
- Not a chat or voice system.
- Not a loadout or inventory: it validates an equipped list it is given, it does not own where that list is stored.
- Not a renderer for markers: it keeps the data (who, where, until when), the game draws them.
- Equipped lists come from the game's own loadout data; the gate holds no identity beyond the key you pass it.

## Rules

- Every limit is configurable, 0 means unlimited where a limit makes sense, and a bad value fails loudly through `GSResult`.
- Time is passed in (`now`, `delta`); core classes never read a clock.
- Everything here is prefixed `GSEmote`. No `uid://` paths.
- Prose says GameSpice, never the internal repo prefix.
- Run the suite with `hv`, never bare Godot. Commit with the owner's identity; never tag.
