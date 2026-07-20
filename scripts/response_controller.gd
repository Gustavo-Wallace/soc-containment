class_name ResponseController
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const ResponseActionType = preload("res://scripts/response_action.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal action_started(action: ResponseActionType)
signal action_progressed(action: ResponseActionType, progress: float, remaining_seconds: float)
signal action_completed(action: ResponseActionType)
signal impact_changed(impact: String)
signal process_terminated(device_id: String)
signal device_isolated(device_id: String)

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var alert_system: AlertSystemType
var active_action: ResponseActionType
var action_started_at := 0.0
var operational_impact := "None"

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType, alerts_value: AlertSystemType) -> void:
	clock = clock_value
	event_log = log_value
	process_store = store_value
	alert_system = alerts_value
	clock.time_changed.connect(_on_time_changed)

func actions_for_process(process_id: String, device_id: String, observed_state: String) -> Array[ResponseActionType]:
	var actions: Array[ResponseActionType] = []
	if process_id != "update_bridge" or device_id != "workstation_a" or observed_state == "Isolated":
		return actions
	var process := process_store.find(process_id, device_id)
	if process == null or process.classification == "Terminated":
		return actions
	actions.append(ResponseActionType.new({"id": "terminate_process", "title": "Terminate Process", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 3.0, "impact": "Low", "benefit": "Stops the process and its associated connection.", "limitation": "Execution origin and possible additional mechanisms remain unknown.", "consequence": "The workstation remains online under monitoring."}))
	actions.append(ResponseActionType.new({"id": "isolate_device", "title": "Isolate Device", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 5.0, "impact": "Medium", "benefit": "Blocks all workstation network communication.", "limitation": "The process remains available for investigation.", "consequence": "The finance workstation becomes unavailable."}))
	return actions

func can_start(device_id: String) -> bool:
	return active_action == null or active_action.target_device_id != device_id

func start(action: ResponseActionType) -> bool:
	if not can_start(action.target_device_id):
		return false
	active_action = action
	action_started_at = clock.elapsed_seconds
	_record("response_started", "Defensive action started: %s." % action.title, action.target_device_id, "Attention")
	action_started.emit(action)
	return true

func _on_time_changed(time_value: float) -> void:
	if active_action == null:
		return
	var elapsed := time_value - action_started_at
	var progress := clampf(elapsed / active_action.duration_seconds, 0.0, 1.0)
	action_progressed.emit(active_action, progress, maxf(0.0, active_action.duration_seconds - elapsed))
	if progress >= 1.0:
		_complete_active_action()

func _complete_active_action() -> void:
	var completed := active_action
	active_action = null
	if completed.id == "terminate_process":
		var process := process_store.find(completed.target_process_id, completed.target_device_id)
		if process != null:
			process.classification = "Terminated"
			process.has_network_activity = false
			process.description = "Process execution was interrupted. Its original execution path remains unverified."
		alert_system.update_current("Monitoring", 0.61, "Process activity was suppressed; the workstation remains under monitoring.")
		_record("alert_updated", "Alert state changed to Monitoring after process suppression.", completed.target_device_id, "Normal")
		_set_impact("Low")
		_record("process_terminated", "update_bridge.exe was terminated; recurring external activity stopped.", completed.target_device_id, "Attention")
		process_terminated.emit(completed.target_device_id)
	else:
		alert_system.update_current("Contained", 0.61, "Workstation A network communication was blocked for containment.")
		_record("alert_updated", "Alert state changed to Contained after device isolation.", completed.target_device_id, "Normal")
		_set_impact("Medium")
		_record("device_isolated", "Workstation A was isolated. Finance workstation availability is affected.", completed.target_device_id, "Attention")
		device_isolated.emit(completed.target_device_id)
	_record("response_completed", "Defensive action completed: %s." % completed.title, completed.target_device_id, "Normal")
	action_completed.emit(completed)

func _set_impact(value: String) -> void:
	operational_impact = value
	_record("operational_impact_changed", "Operational impact changed to %s." % value, "workstation_a", "Normal")
	impact_changed.emit(value)

func _record(event_id: String, summary: String, device_id: String, severity: String) -> void:
	event_log.record(SimulationEventType.new({"id": event_id + "_" + str(int(clock.elapsed_seconds * 10.0)), "timestamp": clock.elapsed_seconds, "event_type": event_id, "source": "SOC Response", "target": device_id, "summary": summary, "additional_data": {}, "visible_to_player": true, "confidence": 0.7, "visual_severity": severity, "related_device_id": device_id}))
