class_name AlertSystem
extends Node

const AlertDataType = preload("res://scripts/alert_data.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal alert_created(alert: AlertDataType)

var alerts: Array[AlertDataType] = []

func configure(event_log: EventLogType) -> void:
	event_log.event_recorded.connect(_on_event_recorded)

func _on_event_recorded(event: SimulationEventType) -> void:
	if event.event_type != "alert_created":
		return
	var alert: AlertDataType = AlertDataType.new({
		"id": event.id,
		"timestamp": event.timestamp,
		"title": event.additional_data.get("title", "Observation alert"),
		"summary": event.summary,
		"source": event.source,
		"confidence": event.confidence,
		"severity": event.visual_severity,
		"state": "Open",
		"related_device_id": event.related_device_id
	})
	alerts.append(alert)
	alert_created.emit(alert)
