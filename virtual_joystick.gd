extends Control

@onready var base = $Base
@onready var knob = $Knob

var max_distance: float = 100.0

var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO

func _ready():
	var current_os = OS.get_name()
	if current_os != "Android" and current_os != "iOS":
		hide()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			var local_pos = event.position - global_position
			if local_pos.length() <= max_distance:
				touch_index = event.index
				_update_knob(event.position)
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			knob.position = Vector2.ZERO
			output_vector = Vector2.ZERO

	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2):
	var drag_offset = touch_pos - global_position
	drag_offset = drag_offset.clamped(max_distance)
	knob.position = drag_offset
	output_vector = drag_offset / max_distance

func get_output() -> Vector2:
	return output_vector
