class_name GSEmotePlayback
extends RefCounted

## Which emote each player is playing now, with no clock of its own: times are passed in. An emote ends when its duration passes, when the player moves (if `cancel_on_move`), or when another starts. The gate decides whether a player MAY play; this tracks that they ARE playing, so every client animates the same thing for the same span.

var _cfg: GSEmoteConfig
var _catalogue: GSEmoteCatalogue
var _active: Dictionary = {}


func _init(cfg: GSEmoteConfig, catalogue: GSEmoteCatalogue) -> void:
	_cfg = cfg
	_catalogue = catalogue


## Starts [param id] for [param player], replacing any current one. The catalogue's duration wins over `default_duration`; both 0 means it holds until cancelled. Fails loudly for an id that is not equippable.
func start(player: Variant, id: StringName, now: float) -> GSResult:
	if not _catalogue.is_equippable(id):
		return GSResult.fail(GSError.CODE_INVALID, "'%s' cannot be played" % id)
	var d := float(_catalogue.get_def(id).get("duration", 0.0))
	if d <= 0.0:
		d = _cfg.default_duration
	_active[player] = {"id": id, "started": now, "ends": now + d if d > 0.0 else INF}
	return GSResult.success(id)


## The id playing for the player at [param now], or empty. An expired emote is dropped here.
func current(player: Variant, now: float) -> StringName:
	var e: Variant = _active.get(player)
	if e == null:
		return &""
	if now >= float((e as Dictionary)["ends"]):
		_active.erase(player)
		return &""
	return (e as Dictionary)["id"]


## Call when the player moves; ends the emote if `cancel_on_move`. Returns true when one was cancelled.
func moved(player: Variant) -> bool:
	if _cfg.cancel_on_move and _active.has(player):
		_active.erase(player)
		return true
	return false


func cancel(player: Variant) -> void:
	_active.erase(player)


## Seconds into the emote, for an animation to seek to; -1 when nothing plays.
func elapsed(player: Variant, now: float) -> float:
	if current(player, now) == &"":
		return -1.0
	return now - float((_active[player] as Dictionary)["started"])


## Drops every emote that has ended and returns how many went, so a server can sweep without asking player by player.
func expire(now: float) -> int:
	var gone: Array = []
	for p: Variant in _active:
		if now >= float((_active[p] as Dictionary)["ends"]):
			gone.append(p)
	for p: Variant in gone:
		_active.erase(p)
	return gone.size()


func forget(player: Variant) -> void:
	_active.erase(player)


func size() -> int:
	return _active.size()
