class_name AlertSystem
extends Node

signal alert_created(alert: AlertData)

var alerts: Array[AlertData] = []

func configure(event_log: EventLog) -> void:
	event_log.event_recorded.connect(_on_event_recorded)

func _on_event_recorded(event: SimulationEvent) -> void:
	if event.event_type != "alert_created":
		return
	var alert := AlertData.new({
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
