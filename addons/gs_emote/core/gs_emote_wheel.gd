class_name GSEmoteWheel
extends RefCounted

## The model of a radial wheel: which slot a stick or mouse offset points at, and what is equipped in each slot. Slot 0 is straight up and slots run clockwise. It draws nothing; a game or GameSpice UI draws the ring from `slot_direction`.

var slots: int
var deadzone: float
var _equipped: Array[StringName] = []


func _init(p_slots: int = 8, p_deadzone: float = 0.25) -> void:
	slots = maxi(1, p_slots)
	deadzone = maxf(0.0, p_deadzone)
	_equipped.resize(slots)
	_equipped.fill(&"")


static func from_config(config: GSEmoteConfig) -> GSEmoteWheel:
	return GSEmoteWheel.new(config.wheel_slots, config.wheel_deadzone)


## The slot an offset points at (screen coordinates, y down), or -1 inside the deadzone.
func slot_at(offset: Vector2) -> int:
	if offset.length() < deadzone:
		return -1
	var a := atan2(offset.x, -offset.y)
	if a < 0.0:
		a += TAU
	var step := TAU / float(slots)
	return int(floorf((a + step * 0.5) / step)) % slots


## Unit direction from the wheel's centre to the middle of a slot.
func slot_direction(slot: int) -> Vector2:
	var a := TAU * float(slot) / float(slots)
	return Vector2(sin(a), -cos(a))


func at(slot: int) -> StringName:
	return _equipped[slot] if slot >= 0 and slot < slots else &""


func equipped() -> Array[StringName]:
	return _equipped.duplicate()


func equip(slot: int, id: StringName, catalogue: GSEmoteCatalogue) -> GSResult:
	if slot < 0 or slot >= slots:
		return GSResult.fail(GSError.CODE_INVALID, "wheel slot %d is outside 0..%d" % [slot, slots - 1])
	if not catalogue.is_equippable(id):
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not an equippable emote, gesture or spray" % id)
	if _equipped.has(id) and _equipped.find(id) != slot:
		return GSResult.fail(GSError.CODE_CONFLICT, "'%s' is already in slot %d" % [id, _equipped.find(id)])
	_equipped[slot] = id
	return GSResult.success(id)


func clear(slot: int) -> void:
	if slot >= 0 and slot < slots:
		_equipped[slot] = &""


## Replaces the whole wheel from a saved list (empty strings are empty slots). Nothing changes if any entry is bad.
func load_equipped(ids: Array, catalogue: GSEmoteCatalogue) -> GSResult:
	if ids.size() > slots:
		return GSResult.fail(GSError.CODE_INVALID, "%d equipped ids do not fit a %d slot wheel" % [ids.size(), slots])
	var next: Array[StringName] = []
	next.resize(slots)
	next.fill(&"")
	for i in ids.size():
		var id := StringName(str(ids[i]))
		if id == &"":
			continue
		if not catalogue.is_equippable(id):
			return GSResult.fail(GSError.CODE_INVALID, "saved slot %d holds '%s', which is not equippable here" % [i, id])
		if next.has(id):
			return GSResult.fail(GSError.CODE_CONFLICT, "saved wheel holds '%s' twice" % id)
		next[i] = id
	_equipped = next
	return GSResult.success(self)
