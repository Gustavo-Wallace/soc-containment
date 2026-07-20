class_name EvidenceData
extends RefCounted

var id: String
var title: String
var source: String
var timestamp: float
var device_id: String
var confidence: String
var summary: String
var facts: PackedStringArray

func _init(values: Dictionary) -> void:
	for key: String in values:
		set(key, values[key])
