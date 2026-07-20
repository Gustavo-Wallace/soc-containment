class_name IncidentSequence
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const ProcessDataType = preload("res://scripts/process_data.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal observation_changed(device_id: String, observed_state: String)
signal unusual_route_changed(is_active: bool)

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var emitted_ids: Dictionary = {}

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType) -> void:
	clock = clock_value
	event_log = log_value
	process_store = store_value
	clock.time_changed.connect(_on_time_changed)

func start() -> void:
	process_store.seed_workstation_a()

func _on_time_changed(time_value: float) -> void:
	_emit_once("routine_sync", 1.5, time_value, _record_routine_sync)
	_emit_once("unverified_process", 7.0, time_value, _record_unverified_process)
	_emit_once("outbound_pattern", 9.0, time_value, _record_outbound_pattern)
	_emit_once("first_alert", 11.5, time_value, _record_alert)

func _emit_once(event_id: String, threshold: float, time_value: float, action: Callable) -> void:
	if time_value < threshold or emitted_ids.has(event_id):
		return
	emitted_ids[event_id] = true
	action.call()

func _record_routine_sync() -> void:
	_record("routine_sync", "legitimate_activity", "Workstation A", "File Server", "Routine document synchronization completed.", 0.92, "Normal", "workstation_a")

func _record_unverified_process() -> void:
	process_store.add(ProcessDataType.new({"id": "update_bridge", "device_id": "workstation_a", "process_name": "update_bridge.exe", "user_name": "analyst.user", "publisher": "Unknown publisher", "file_path": "C:/Users/analyst.user/AppData/Local/Bridge/update_bridge.exe", "started_at": clock.elapsed_seconds, "classification": "Unverified", "has_network_activity": true, "description": "Started shortly before the recurring external connection. No prior record exists in this workstation profile."}))
	_record("unverified_process", "process_started", "Workstation A", "", "Process update_bridge.exe started from an uncommon local path.", 0.46, "Attention", "workstation_a")

func _record_outbound_pattern() -> void:
	_record("outbound_pattern", "external_connection_observed", "Workstation A", "Internet", "Recurring outbound connection observed via the corporate gateway.", 0.58, "Attention", "workstation_a")
	unusual_route_changed.emit(true)

func _record_alert() -> void:
	clock.set_speed(1.0)
	_record("first_alert", "alert_created", "Network Sensor", "Workstation A", "Workstation A generated a recurring external connection outside its usual activity profile.", 0.61, "Attention", "workstation_a", {"title": "Repeated outbound pattern"})
	observation_changed.emit("workstation_a", "Anomaly observed")

func _record(id: String, event_type: String, source: String, target: String, summary: String, confidence: float, severity: String, device_id: String, extra: Dictionary = {}) -> void:
	event_log.record(SimulationEventType.new({"id": id, "timestamp": clock.elapsed_seconds, "event_type": event_type, "source": source, "target": target, "summary": summary, "additional_data": extra, "visible_to_player": true, "confidence": confidence, "visual_severity": severity, "related_device_id": device_id}))
