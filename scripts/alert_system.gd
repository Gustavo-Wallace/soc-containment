class_name AlertSystem
extends Node

const AlertDataType = preload("res://scripts/alert_data.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal alert_created(alert: AlertDataType)
signal alert_updated(alert: AlertDataType)

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
		"related_device_id": event.related_device_id,
		"priority": event.additional_data.get("priority", event.visual_severity),
		"context_kind": event.additional_data.get("context_kind", "incident")
	})
	alerts.append(alert)
	alert_created.emit(alert)

func update_current(state: String, confidence: float, summary: String) -> void:
	var alert := primary_alert()
	if alert == null:
		return
	alert.state = state
	alert.confidence = confidence
	alert.summary = summary
	alert_updated.emit(alert)

func primary_alert() -> AlertDataType:
	for alert: AlertDataType in alerts:
		if alert.context_kind == "incident":
			return alert
	return null

func alert_for_device(device_id: String) -> AlertDataType:
	for alert: AlertDataType in alerts:
		if alert.related_device_id == device_id:
			return alert
	return null

func close_as_benign(device_id: String) -> void:
	var alert := alert_for_device(device_id)
	if alert == null:
		return
	alert.state = "Benign"
	alert.triage_status = "Verified Benign" if alert.reviewed else "Unsupported Closure"
	alert_updated.emit(alert)
