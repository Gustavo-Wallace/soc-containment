class_name AlertData
extends RefCounted

var id: String
var timestamp: float
var title: String
var summary: String
var source: String
var confidence: float
var severity: String
var state: String
var related_device_id: String
var priority: String = "Attention"
var context_kind: String = "incident"
var triage_status: String = "Unresolved Alert"
var reviewed := false

func _init(values: Dictionary) -> void:
	for key: String in values:
		set(key, values[key])
