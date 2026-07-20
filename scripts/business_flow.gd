class_name BusinessFlow
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal flow_changed
signal sync_started(timestamp: float)
signal sync_missed(timestamp: float)

var clock: SimulationClockType
var event_log: EventLogType
var flow_name := "Finance Document Sync"
var source_device_id := "workstation_a"
var destination_device_id := "file_server"
var state := "Healthy"
var criticality := "Medium"
var interval_seconds := 14.0
var last_execution := -1.0
var next_execution := 4.0
var completed_runs := 0
var missed_runs := 0
var downtime_seconds := 0.0
var is_isolated := false
var last_clock_time := 0.0

func configure(clock_value: SimulationClockType, log_value: EventLogType) -> void:
	clock = clock_value
	event_log = log_value
	clock.time_changed.connect(_on_time_changed)

func set_isolated(value: bool) -> void:
	is_isolated = value
	state = "Interrupted" if value else "Healthy"
	flow_changed.emit()

func _on_time_changed(time_value: float) -> void:
	if is_isolated:
		downtime_seconds += maxf(0.0, time_value - last_clock_time)
	last_clock_time = time_value
	if time_value < next_execution:
		return
	while time_value >= next_execution:
		if is_isolated:
			missed_runs += 1
			_record("business_sync_missed", "Finance document synchronization could not be completed because Workstation A is isolated.")
			sync_missed.emit(next_execution)
		else:
			completed_runs += 1
			last_execution = next_execution
			_record("business_sync_completed", "Finance Document Sync completed through the corporate gateway.")
			sync_started.emit(next_execution)
		next_execution += interval_seconds
		flow_changed.emit()

func _record(event_id: String, summary: String) -> void:
	event_log.record(SimulationEventType.new({"id": event_id + "_" + str(int(clock.elapsed_seconds * 10.0)), "timestamp": clock.elapsed_seconds, "event_type": event_id, "source": "Finance Operations", "target": "File Server", "summary": summary, "additional_data": {}, "visible_to_player": true, "confidence": 0.95, "visual_severity": "Normal", "related_device_id": "workstation_a"}))
