class_name GSEmoteWheelView
extends Control

## Draws a [GSEmoteWheel] with _draw: a ring of slots, the highlighted one filled, each labelled with its equipped id. No textures; a game swaps the label for an icon by listening to [signal slot_chosen]. Idle (no processing) until [method point] or [method choose] is called.

signal slot_chosen(slot: int, id: StringName)

@export var radius: float = 120.0
@export var ring_colour := Color(1, 1, 1, 0.25)
@export var hot_colour := Color(1, 0.8, 0.3, 0.7)

var _wheel: GSEmoteWheel
var _hot: int = -1


func setup(wheel: GSEmoteWheel) -> void:
	_wheel = wheel
	queue_redraw()


## Highlights the slot an offset from the centre points at (-1 inside the deadzone). Redraws only when it changes.
func point(offset: Vector2) -> int:
	var s := _wheel.slot_at(offset) if _wheel != null else -1
	if s != _hot:
		_hot = s
		queue_redraw()
	return s


## Confirms the highlighted slot, e.g. on release, and emits the id (empty for an empty slot).
func choose() -> StringName:
	if _wheel == null or _hot < 0:
		return &""
	var id := _wheel.at(_hot)
	slot_chosen.emit(_hot, id)
	return id


func _draw() -> void:
	if _wheel == null:
		return
	var c := size * 0.5
	var step := TAU / float(_wheel.slots)
	var font := ThemeDB.fallback_font
	for i in _wheel.slots:
		var dir := _wheel.slot_direction(i)
		var col := hot_colour if i == _hot else ring_colour
		var a0 := -PI * 0.5 + step * (float(i) - 0.5)
		draw_arc(c, radius, a0, a0 + step, 12, col, 14.0)
		var id := _wheel.at(i)
		if id != &"":
			draw_string(font, c + dir * radius * 0.65 - Vector2(20, 0), String(id), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 12)
