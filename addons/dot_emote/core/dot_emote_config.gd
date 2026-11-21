class_name GSEmoteConfig
extends GSConfig

## Every tunable of GameSpice Emote. A game binds it with GSGameConfigBinder (kind `emote`); `cfg/addon/dot_emote/*.yml`, `DOT_EMOTE_*` and `--emote-*` layer over these defaults. Ranges are inspector slider limits, not caps; set a value from code or a file to go beyond them.

const ADDON := "dot-emote"

## Master switch: off, the gate refuses every use, ping and marker.
@export var enabled: bool = true

@export_group("Wheel")
## Slots on the radial wheel.
@export_range(1, 16, 1) var wheel_slots: int = 8
## Stick or mouse distance (0 to 1) under which no slot is picked.
@export_range(0.0, 1.0, 0.01) var wheel_deadzone: float = 0.25
## Key that opens the wheel (the game binds it).
@export var key: String = "G"

@export_group("Playback")
## Whether an emote in progress ends when the player moves; false lets it play out.
@export var cancel_on_move: bool = true
## Seconds an emote with no duration of its own plays; 0 holds it until cancelled.
@export_range(0.0, 60.0, 0.1) var default_duration: float = 2.0

@export_group("Limits")
## Seconds between two emotes by one player; 0 is no cooldown.
@export_range(0.0, 30.0, 0.1) var emote_cooldown: float = 1.5
## Seconds between two pings by one player; 0 is no cooldown.
@export_range(0.0, 10.0, 0.1) var ping_cooldown: float = 0.4
## Pings one player may send inside `ping_window`; 0 is unlimited.
@export_range(0, 64, 1) var ping_burst: int = 4
## Seconds the ping burst is counted over.
@export_range(0.5, 120.0, 0.5) var ping_window: float = 6.0
## Map markers one player may keep at once; 0 is unlimited.
@export_range(0, 64, 1) var markers_per_player: int = 4
## Seconds a marker lives; 0 never expires.
@export_range(0.0, 600.0, 1.0) var marker_ttl: float = 30.0


func env_prefix() -> String:
	return "DOT_EMOTE_"


func cli_prefix() -> String:
	return "--emote-"


func validate() -> GSResult:
	if wheel_slots < 1:
		return GSResult.fail(GSError.CODE_INVALID, "emote wheel_slots %d is under 1" % wheel_slots)
	for pair: Array in [["emote_cooldown", emote_cooldown], ["ping_cooldown", ping_cooldown], ["ping_window", ping_window], ["marker_ttl", marker_ttl], ["wheel_deadzone", wheel_deadzone]]:
		if float(pair[1]) < 0.0:
			return GSResult.fail(GSError.CODE_INVALID, "emote %s %s is negative" % [pair[0], pair[1]])
	if ping_burst < 0 or markers_per_player < 0:
		return GSResult.fail(GSError.CODE_INVALID, "emote ping_burst and markers_per_player are 0 (unlimited) or more")
	if default_duration < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "emote default_duration is negative (0 holds until cancelled)")
	return GSResult.success(self)


## Defaults, then `cfg/addon/dot_emote/*.yml` and the game tier, then environment and command line.
static func from_files() -> GSResult:
	var cfg := GSEmoteConfig.new()
	var files := GSAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "emote %s wheel %d cooldown %.1fs ping %.1fs x%d/%.0fs markers %d ttl %.0fs" % [
		"on" if enabled else "disabled", wheel_slots, emote_cooldown, ping_cooldown, ping_burst, ping_window, markers_per_player, marker_ttl]
