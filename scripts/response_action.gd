class_name ResponseAction
extends RefCounted

var id: String
var title: String
var target_device_id: String
var target_process_id: String
var duration_seconds: float
var impact: String
var benefit: String
var limitation: String
var consequence: String

func _init(values: Dictionary) -> void:
	for key: String in values:
		set(key, values[key])
