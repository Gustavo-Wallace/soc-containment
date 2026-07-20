class_name SimulationEvent
extends RefCounted

var id: String
var timestamp: float
var event_type: String
var source: String
var target: String
var summary: String
var additional_data: Dictionary
var visible_to_player: bool
var confidence: float
var visual_severity: String
var related_device_id: String

func _init(values: Dictionary) -> void:
	additional_data = {}
	for key: String in values:
		set(key, values[key])
