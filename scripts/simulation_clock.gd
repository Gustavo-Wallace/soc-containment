class_name SimulationClock
extends Node

signal time_changed(elapsed_seconds: float)
signal paused_changed(is_paused: bool)
signal speed_changed(multiplier: float)

var elapsed_seconds := 0.0
var is_paused := false
var speed_multiplier := 1.0

func _process(delta: float) -> void:
	if is_paused:
		return
	elapsed_seconds += delta * speed_multiplier
	time_changed.emit(elapsed_seconds)

func toggle_pause() -> void:
	is_paused = not is_paused
	paused_changed.emit(is_paused)

func set_speed(multiplier: float) -> void:
	var next := 2.0 if is_equal_approx(multiplier, 2.0) else 1.0
	if is_equal_approx(speed_multiplier, next):
		return
	speed_multiplier = next
	speed_changed.emit(speed_multiplier)

func formatted_time() -> String:
	var whole_seconds := int(elapsed_seconds)
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]
