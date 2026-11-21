class_name DotEmoteCatalogue
extends RefCounted

## What can be played: emotes, gestures, sprays, pings and map markers, each with an id, a kind and a label. Pure data; art and sound belong to the game and its packs, this only knows ids.

const KIND_EMOTE := &"emote"
const KIND_GESTURE := &"gesture"
const KIND_SPRAY := &"spray"
const KIND_PING := &"ping"
const KIND_MARKER := &"marker"
const KINDS: Array[StringName] = [KIND_EMOTE, KIND_GESTURE, KIND_SPRAY, KIND_PING, KIND_MARKER]
## Kinds that go on the wheel and need an equip; pings and markers are world actions.
const EQUIPPABLE: Array[StringName] = [KIND_EMOTE, KIND_GESTURE, KIND_SPRAY]

var _defs: Dictionary = {}


## Adds `{id, kind, label?, duration?, tags?}`. Fails loudly on an empty id, an unknown kind or a repeated id.
func add(def: Dictionary) -> DotResult:
	var id := StringName(str(def.get("id", "")))
	if id == &"":
		return DotResult.fail(DotError.CODE_INVALID, "emote def has no id")
	var kind := StringName(str(def.get("kind", "")))
	if not KINDS.has(kind):
		return DotResult.fail(DotError.CODE_INVALID, "emote '%s' has unknown kind '%s'" % [id, kind])
	if _defs.has(id):
		return DotResult.fail(DotError.CODE_CONFLICT, "emote id '%s' is already in the catalogue" % id)
	var duration := float(def.get("duration", 0.0))
	if duration < 0.0:
		return DotResult.fail(DotError.CODE_INVALID, "emote '%s' has a negative duration" % id)
	var tags := PackedStringArray()
	for t: Variant in (def.get("tags", []) as Array):
		tags.append(str(t))
	_defs[id] = {"id": id, "kind": kind, "label": str(def.get("label", String(id))), "duration": duration, "tags": tags}
	return DotResult.success(id)


func has(id: StringName) -> bool:
	return _defs.has(id)


func size() -> int:
	return _defs.size()


## A copy of the def, or an empty dictionary.
func get_def(id: StringName) -> Dictionary:
	return (_defs[id] as Dictionary).duplicate() if _defs.has(id) else {}


func kind_of(id: StringName) -> StringName:
	return (_defs[id] as Dictionary)["kind"] if _defs.has(id) else &""


## Ids of one kind, sorted, so a wheel built from them is the same on every machine.
func ids_of_kind(kind: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _defs:
		if (_defs[id] as Dictionary)["kind"] == kind:
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


func is_equippable(id: StringName) -> bool:
	return EQUIPPABLE.has(kind_of(id))
