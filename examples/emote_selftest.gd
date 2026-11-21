extends Node

## dot-emote's headless suite (res://examples/emote_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error aborts a section and not the run.

const EXPECTED_SECTIONS := 7
const EXPECTED_CHECKS := 74

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-emote")
	_config()
	_catalogue()
	_wheel()
	_gate_use()
	_gate_ping_markers()
	_layers()
	_playback()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _book() -> GSEmoteCatalogue:
	var c := GSEmoteCatalogue.new()
	for d: Dictionary in [
		{"id": "wave", "kind": "emote", "duration": 2.0},
		{"id": "dance", "kind": "emote", "tags": ["loop"]},
		{"id": "thumbs", "kind": "gesture"},
		{"id": "tag", "kind": "spray"},
		{"id": "look", "kind": "ping"},
		{"id": "danger", "kind": "marker"},
	]:
		c.add(d)
	return c


func _config() -> void:
	var c := GSEmoteConfig.new()
	_check(c.validate().ok, "defaults validate")
	c.wheel_slots = 0
	_check(not c.validate().ok and c.validate().error.code == GSError.CODE_INVALID, "zero slots fail loudly")
	c.wheel_slots = 8
	c.ping_burst = -1
	_check(not c.validate().ok, "a negative burst fails (0 is the unlimited value)")
	c.ping_burst = 0
	_check(c.validate().ok, "ping_burst 0 is valid and means unlimited")
	_check(c.env_prefix() == "DOT_EMOTE_" and c.cli_prefix() == "--emote-", "env and command-line prefixes")
	_check(c.config_keys().size() >= 10, "every tunable is a config key", str(c.config_keys().size()))
	_sections += 1


func _catalogue() -> void:
	var c := _book()
	_check(c.size() == 6 and c.has(&"wave") and not c.has(&"nope"), "six defs added")
	_check(not c.add({"id": "wave", "kind": "emote"}).ok and c.add({"id": "wave", "kind": "emote"}).error.code == GSError.CODE_CONFLICT, "a repeated id is a conflict")
	_check(not c.add({"kind": "emote"}).ok, "no id fails")
	_check(not c.add({"id": "x", "kind": "dance"}).ok, "an unknown kind fails")
	_check(not c.add({"id": "y", "kind": "emote", "duration": -1.0}).ok, "a negative duration fails")
	_check(c.ids_of_kind(&"emote") == [&"dance", &"wave"], "ids of a kind are sorted")
	_check(c.get_def(&"dance")["tags"] == PackedStringArray(["loop"]) and c.get_def(&"wave")["label"] == "wave", "tags and the default label")
	_check(c.is_equippable(&"tag") and not c.is_equippable(&"look") and not c.is_equippable(&"danger"), "pings and markers are not equippable")
	_check(c.get_def(&"missing").is_empty() and c.kind_of(&"missing") == &"", "a missing id gives an empty def")
	_sections += 1


func _wheel() -> void:
	var w := GSEmoteWheel.new(8, 0.25)
	_check(w.slot_at(Vector2(0, -1)) == 0, "up is slot 0")
	_check(w.slot_at(Vector2(1, 0)) == 2 and w.slot_at(Vector2(0, 1)) == 4 and w.slot_at(Vector2(-1, 0)) == 6, "right, down and left run clockwise")
	_check(w.slot_at(Vector2(1, -1)) == 1 and w.slot_at(Vector2(-1, -1)) == 7, "diagonals are the slots between")
	_check(w.slot_at(Vector2(0.1, 0.1)) == -1 and w.slot_at(Vector2.ZERO) == -1, "inside the deadzone picks nothing")
	_check(w.slot_at(Vector2(-0.01, -1)) == 0 and w.slot_at(Vector2(0.38, -1)) == 0 and w.slot_at(Vector2(0.45, -1)) == 1, "a slot spans an eighth of the ring around its centre")
	_check(w.slot_direction(2).is_equal_approx(Vector2(1, 0)) and w.slot_direction(0).is_equal_approx(Vector2(0, -1)), "slot_direction points at the slot's middle")
	var one := GSEmoteWheel.new(1, 0.0)
	_check(one.slot_at(Vector2(3, 4)) == 0, "a one slot wheel is always slot 0")
	var cat := _book()
	_check(w.equip(0, &"wave", cat).ok and w.at(0) == &"wave", "equip fills a slot")
	_check(w.equip(1, &"wave", cat).error.code == GSError.CODE_CONFLICT, "one emote may not fill two slots")
	_check(w.equip(0, &"wave", cat).ok, "re-equipping the same slot is fine")
	_check(not w.equip(2, &"look", cat).ok and not w.equip(2, &"ghost", cat).ok, "a ping or an unknown id is refused")
	_check(not w.equip(8, &"dance", cat).ok and not w.equip(-1, &"dance", cat).ok, "a slot out of range is refused")
	w.clear(0)
	_check(w.at(0) == &"" and w.at(99) == &"", "clear empties a slot and at() is safe out of range")
	_check(w.load_equipped(["wave", "", "thumbs"], cat).ok and w.at(2) == &"thumbs" and w.at(1) == &"", "load_equipped restores a saved wheel")
	_check(not w.load_equipped(["wave", "wave"], cat).ok and w.at(0) == &"wave", "a bad saved wheel changes nothing")
	_check(not w.load_equipped(["a", "b", "c", "d", "e", "f", "g", "h", "i"], cat).ok, "too many saved ids fail loudly")
	_check(GSEmoteWheel.from_config(GSEmoteConfig.new()).slots == 8, "from_config reads the slot count")
	_sections += 1


func _gate() -> GSEmoteGate:
	var cfg := GSEmoteConfig.new()
	cfg.emote_cooldown = 2.0
	cfg.ping_cooldown = 0.5
	cfg.ping_burst = 3
	cfg.ping_window = 10.0
	cfg.markers_per_player = 2
	cfg.marker_ttl = 20.0
	return GSEmoteGate.new(cfg, _book())


func _gate_use() -> void:
	var g := _gate()
	_check(g.set_equipped(1, ["wave", "tag"]).ok, "equip two")
	_check(not g.set_equipped(1, ["wave", "look"]).ok and g.use(1, &"wave", 0.0).ok, "a bad equip list changes nothing")
	_check(g.use(1, &"wave", 0.0).error.code == GSError.CODE_RATE_LIMITED, "a second use inside the cooldown is rate limited")
	_check(g.use(1, &"wave", 1.9).error.code == GSError.CODE_RATE_LIMITED and g.use(1, &"wave", 2.0).ok, "the cooldown ends at exactly emote_cooldown")
	_check(g.use(1, &"dance", 10.0).error.code == GSError.CODE_FORBIDDEN, "an emote that is not equipped is forbidden")
	_check(g.use(2, &"wave", 10.0).error.code == GSError.CODE_FORBIDDEN, "another player has nothing equipped")
	_check(g.use(1, &"ghost", 10.0).error.code == GSError.CODE_INVALID and g.use(1, &"look", 10.0).error.code == GSError.CODE_INVALID, "unknown ids and pings are invalid for use")
	g.config.emote_cooldown = 0.0
	_check(g.use(1, &"wave", 10.0).ok and g.use(1, &"wave", 10.0).ok, "cooldown 0 is no cooldown")
	g.config.enabled = false
	_check(g.use(1, &"wave", 99.0).error.code == GSError.CODE_FORBIDDEN, "the master switch refuses everything")
	g.forget(1)
	g.config.enabled = true
	_check(g.use(1, &"wave", 100.0).error.code == GSError.CODE_FORBIDDEN, "forget drops the equipped list")
	_sections += 1


func _gate_ping_markers() -> void:
	var g := _gate()
	_check(g.ping(1, &"look", 0.0).ok, "a ping goes")
	_check(g.ping(1, &"look", 0.3).error.code == GSError.CODE_RATE_LIMITED, "a ping inside the cooldown is refused")
	_check(g.ping(1, &"look", 1.0).ok and g.ping(1, &"look", 2.0).ok, "pings spaced by the cooldown go")
	_check(g.ping(1, &"look", 3.0).error.code == GSError.CODE_RATE_LIMITED, "the fourth ping in the window is refused")
	_check(g.ping(1, &"look", 10.5).ok, "the window slides")
	_check(g.ping(2, &"look", 3.0).ok, "the burst is per player")
	g.config.ping_burst = 0
	g.config.ping_cooldown = 0.0
	var all_ok := true
	for i in 50:
		all_ok = all_ok and g.ping(3, &"look", 100.0 + i * 0.01).ok
	_check(all_ok, "ping_burst 0 is unlimited")
	_check(g.ping(1, &"wave", 500.0).error.code == GSError.CODE_INVALID, "an emote is not a ping")
	_check(g.place_marker(1, &"danger", Vector3(1, 0, 2), 0.0).ok and g.place_marker(1, &"danger", Vector3.ZERO, 1.0).ok, "two markers fit")
	_check(g.place_marker(1, &"danger", Vector3.ZERO, 2.0).error.code == GSError.CODE_QUOTA, "the third hits the limit and fails loudly")
	_check(g.markers_of(1, 5.0).size() == 2 and g.markers_of(1, 20.5).size() == 1 and g.markers_of(1, 25.0).is_empty(), "markers expire at their ttl")
	_check(g.place_marker(1, &"danger", Vector3.ZERO, 30.0).ok, "expired markers free their slot")
	g.config.markers_per_player = 0
	g.config.marker_ttl = 0.0
	for i in 20:
		g.place_marker(4, &"danger", Vector3.ZERO, float(i))
	_check(g.markers_of(4, 1.0e6).size() == 20, "markers_per_player 0 and ttl 0 mean no limit and no expiry")
	_check(g.place_marker(1, &"look", Vector3.ZERO, 0.0).error.code == GSError.CODE_INVALID, "a ping is not a marker")
	g.clear_markers(4)
	_check(g.markers_of(4, 0.0).is_empty(), "clear_markers empties a player")
	_sections += 1


func _layers() -> void:
	var c := GSEmoteConfig.new()
	var applied := c.apply_dictionary({"wheel_slots": 6, "emote_cooldown": 0.5, "enabled": false, "key": "B"})
	_check(applied.size() == 4 and c.wheel_slots == 6 and c.emote_cooldown == 0.5 and not c.enabled and c.key == "B", "a dictionary layer sets every type", str(applied))
	var r := GSEmoteConfig.from_files()
	_check(r.ok and r.value is GSEmoteConfig, "from_files returns a config")
	_check((r.value as GSEmoteConfig).describe().begins_with("emote"), "describe says what it is")
	_sections += 1


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)


func _playback() -> void:
	var c := GSEmoteConfig.new()
	var cat := GSEmoteCatalogue.new()
	cat.add({"id": "wave", "kind": "emote", "duration": 3.0})
	cat.add({"id": "dance", "kind": "emote"})
	cat.add({"id": "here", "kind": "ping"})
	var pb := GSEmotePlayback.new(c, cat)
	_check(not pb.start(1, &"here", 0.0).ok, "a ping is not a playable emote")
	_check(pb.start(1, &"wave", 10.0).ok and pb.current(1, 11.0) == &"wave", "a started emote is current")
	_check(pb.current(1, 13.0) == &"" and pb.size() == 0, "it ends at its own duration and is dropped")
	pb.start(1, &"dance", 0.0)
	_check(pb.current(1, 1.9) == &"dance" and pb.current(1, 2.1) == &"", "no duration uses default_duration")
	c.default_duration = 0.0
	pb.start(1, &"dance", 0.0)
	_check(pb.current(1, 1.0e6) == &"dance", "default_duration 0 holds until cancelled")
	_check(pb.moved(1) and pb.current(1, 1.0) == &"", "moving cancels")
	c.cancel_on_move = false
	pb.start(1, &"wave", 0.0)
	_check(not pb.moved(1) and pb.current(1, 1.0) == &"wave", "cancel_on_move off lets it play out")
	_check(is_equal_approx(pb.elapsed(1, 1.5), 1.5) and pb.elapsed(2, 1.5) == -1.0, "elapsed seeks, and is -1 when idle")
	pb.start(2, &"wave", 0.0)
	pb.start(3, &"wave", 0.0)
	_check(pb.expire(5.0) == 3 and pb.size() == 0, "expire sweeps every ended emote")
	pb.start(1, &"wave", 0.0)
	pb.forget(1)
	_check(pb.size() == 0, "forget drops a player who left")
	c.default_duration = -1.0
	_check(not c.validate().ok, "a negative default_duration is refused")
	var w := GSEmoteWheel.new(4, 0.25)
	w.equip(0, &"wave", cat)
	var v := GSEmoteWheelView.new()
	v.setup(w)
	_check(v.point(Vector2(0, -1)) == 0 and v.choose() == &"wave", "the view points at a slot and chooses its id")
	_check(v.point(Vector2.ZERO) == -1 and v.choose() == &"", "inside the deadzone chooses nothing")
	v.free()
	_sections += 1
