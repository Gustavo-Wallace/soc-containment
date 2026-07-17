class_name DeviceData
extends RefCounted

var id: String
var display_name: String
var category: String
var operational_role: String
var zone: String
var address: String
var description: String
var importance: String
var position: Vector2
var kind: String
var operational_state: String = "Operational"

func _init(values: Dictionary) -> void:
	for key: String in values:
		set(key, values[key])
