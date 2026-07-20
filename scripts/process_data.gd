class_name ProcessData
extends RefCounted

var id: String
var device_id: String
var process_name: String
var user_name: String
var publisher: String
var file_path: String
var started_at: float
var classification: String
var has_network_activity: bool
var description: String

func _init(values: Dictionary) -> void:
	for key: String in values:
		set(key, values[key])
