# Playback and the wheel

`GSEmoteGate` decides whether a player may play; `GSEmotePlayback` tracks that they are playing, from `start(player, id, now)` until the catalogue duration (or `default_duration`) passes, the player moves, or another emote starts. `expire(now)` sweeps a server's table without asking player by player. `GSEmoteWheelView` draws a `GSEmoteWheel` and is idle until `point()` or `choose()` is called.

No generic emote code existed elsewhere in the repositories to move; the existing hits were unrelated.
