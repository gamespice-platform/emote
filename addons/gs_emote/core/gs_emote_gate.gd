class_name GSEmoteGate
extends RefCounted

## The server's side: nothing a client asks for is trusted. It checks that an emote is in the catalogue and equipped by that player, and enforces the cooldown, the ping burst and the marker limit. Time is passed in (`now`, seconds), so it is deterministic and testable. Equipped lists come from wherever the game keeps them (for example GameSpice Game's avatar loadouts); this holds no identity of its own.

var config: GSEmoteConfig
var catalogue: GSEmoteCatalogue

var _equipped: Dictionary = {}
var _last_emote: Dictionary = {}
var _last_ping: Dictionary = {}
var _pings: Dictionary = {}
var _markers: Dictionary = {}


func _init(p_config: GSEmoteConfig, p_catalogue: GSEmoteCatalogue) -> void:
	config = p_config
	catalogue = p_catalogue


## Records what a player has equipped; every id must be equippable. Nothing changes on a bad list.
func set_equipped(player: Variant, ids: Array) -> GSResult:
	var clean: Array[StringName] = []
	for raw: Variant in ids:
		var id := StringName(str(raw))
		if id == &"":
			continue
		if not catalogue.is_equippable(id):
			return GSResult.fail(GSError.CODE_INVALID, "'%s' cannot be equipped" % id)
		clean.append(id)
	_equipped[player] = clean
	return GSResult.success(clean.size())


## A player plays an emote, gesture or spray. Success carries the id.
func use(player: Variant, id: StringName, now: float) -> GSResult:
	if not config.enabled:
		return GSResult.fail(GSError.CODE_FORBIDDEN, "emotes are switched off")
	if not catalogue.is_equippable(id):
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not an emote, gesture or spray" % id)
	if not (_equipped.get(player, []) as Array).has(id):
		return GSResult.fail(GSError.CODE_FORBIDDEN, "'%s' is not equipped by this player" % id)
	if _last_emote.has(player):
		var wait: float = float(_last_emote[player]) + config.emote_cooldown - now
		if wait > 0.0:
			return GSResult.fail(GSError.CODE_RATE_LIMITED, "emote cooldown, %.2fs left" % wait)
	_last_emote[player] = now
	return GSResult.success(id)


## A player pings. Spaced by `ping_cooldown` and bounded to `ping_burst` per `ping_window` (0 is unlimited).
func ping(player: Variant, id: StringName, now: float) -> GSResult:
	if not config.enabled:
		return GSResult.fail(GSError.CODE_FORBIDDEN, "emotes are switched off")
	if catalogue.kind_of(id) != GSEmoteCatalogue.KIND_PING:
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not a ping" % id)
	if _last_ping.has(player) and float(_last_ping[player]) + config.ping_cooldown > now:
		return GSResult.fail(GSError.CODE_RATE_LIMITED, "ping cooldown")
	var times: Array = _pings.get(player, [])
	times = times.filter(func(t: Variant) -> bool: return float(t) > now - config.ping_window)
	if config.ping_burst > 0 and times.size() >= config.ping_burst:
		_pings[player] = times
		return GSResult.fail(GSError.CODE_RATE_LIMITED, "%d pings in %.0fs is the limit" % [config.ping_burst, config.ping_window])
	times.append(now)
	_pings[player] = times
	_last_ping[player] = now
	return GSResult.success(id)


## A player puts a marker on the map. Fails loudly at `markers_per_player` (0 is unlimited); expired markers do not count.
func place_marker(player: Variant, id: StringName, at: Vector3, now: float) -> GSResult:
	if not config.enabled:
		return GSResult.fail(GSError.CODE_FORBIDDEN, "emotes are switched off")
	if catalogue.kind_of(id) != GSEmoteCatalogue.KIND_MARKER:
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not a map marker" % id)
	var live := markers_of(player, now)
	if config.markers_per_player > 0 and live.size() >= config.markers_per_player:
		return GSResult.fail(GSError.CODE_QUOTA, "this player already has %d markers" % live.size())
	var expires := now + config.marker_ttl if config.marker_ttl > 0.0 else INF
	live.append({"id": id, "at": at, "expires": expires})
	_markers[player] = live
	return GSResult.success(live.size())


## The player's live markers, expired ones dropped.
func markers_of(player: Variant, now: float) -> Array:
	var live: Array = (_markers.get(player, []) as Array).filter(func(m: Variant) -> bool: return float((m as Dictionary)["expires"]) > now)
	_markers[player] = live
	return live


func clear_markers(player: Variant) -> void:
	_markers.erase(player)


## Drop everything held for a player who left.
func forget(player: Variant) -> void:
	for d: Dictionary in [_equipped, _last_emote, _last_ping, _pings, _markers]:
		d.erase(player)
