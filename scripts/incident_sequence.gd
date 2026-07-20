class_name IncidentSequence
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const ProcessDataType = preload("res://scripts/process_data.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")
const AttackerStateType = preload("res://scripts/attacker_state.gd")

signal observation_changed(device_id: String, observed_state: String)
signal unusual_route_changed(is_active: bool)
signal suspicious_access_attempt(timestamp: float)
signal file_server_session_established(timestamp: float)
signal abnormal_transfer_started(timestamp: float)
signal remote_support_started(timestamp: float)

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var identity_context: IdentityContextType
var attacker: AttackerStateType
var emitted_ids: Dictionary = {}
var alert_started_at := -1.0
var escalation_prevented := false
var escalation_started_at := -1.0
var session_started_at := -1.0

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType, identity_value: IdentityContextType, attacker_value: AttackerStateType) -> void:
	clock = clock_value
	event_log = log_value
	process_store = store_value
	identity_context = identity_value
	attacker = attacker_value
	clock.time_changed.connect(_on_time_changed)

func start() -> void:
	process_store.seed_workstation_a()

func _on_time_changed(time_value: float) -> void:
	_emit_once("routine_sync", 1.5, time_value, _record_routine_sync)
	_emit_once("unverified_process", 7.0, time_value, _record_unverified_process)
	_emit_once("outbound_pattern", 9.0, time_value, _record_outbound_pattern)
	_emit_once("first_alert", 11.5, time_value, _record_alert)
	if alert_started_at >= 0.0:
		_emit_once("remote_support", alert_started_at + 4.5, time_value, _record_remote_support)
	if alert_started_at >= 0.0 and not escalation_prevented:
		_emit_once("file_server_attempt", alert_started_at + 15.0, time_value, _record_file_server_attempt)
	if escalation_started_at >= 0.0 and not escalation_prevented:
		_emit_once("file_server_session", escalation_started_at + 12.0, time_value, _record_file_server_session)
	if session_started_at >= 0.0 and not escalation_prevented:
		_emit_once("abnormal_transfer", session_started_at + 8.0, time_value, _record_abnormal_transfer)

func _emit_once(event_id: String, threshold: float, time_value: float, action: Callable) -> void:
	if time_value < threshold or emitted_ids.has(event_id):
		return
	emitted_ids[event_id] = true
	action.call()

func _record_routine_sync() -> void:
	_record("routine_sync", "legitimate_activity", "Workstation A", "File Server", "Routine document synchronization completed.", 0.92, "Normal", "workstation_a")

func _record_unverified_process() -> void:
	if not attacker.execute("start_process"):
		return
	process_store.add(ProcessDataType.new({"id": "update_bridge", "device_id": "workstation_a", "process_name": "update_bridge.exe", "user_name": "analyst.user", "publisher": "Unknown publisher", "file_path": "C:/Users/analyst.user/AppData/Local/Bridge/update_bridge.exe", "started_at": clock.elapsed_seconds, "classification": "Unverified", "has_network_activity": true, "description": "Started shortly before the recurring external connection. No prior record exists in this workstation profile."}))
	_record("unverified_process", "process_started", "Workstation A", "", "Process update_bridge.exe started from an uncommon local path.", 0.46, "Attention", "workstation_a")

func _record_outbound_pattern() -> void:
	if not attacker.execute("external_communication"):
		return
	_record("outbound_pattern", "external_connection_observed", "Workstation A", "Internet", "Recurring outbound connection observed via the corporate gateway.", 0.58, "Attention", "workstation_a")
	unusual_route_changed.emit(true)

func _record_alert() -> void:
	clock.set_speed(1.0)
	_record("first_alert", "alert_created", "Network Sensor", "Workstation A", "Workstation A generated a recurring external connection outside its usual activity profile.", 0.61, "Attention", "workstation_a", {"title": "Repeated outbound pattern"})
	observation_changed.emit("workstation_a", "Anomaly observed")
	alert_started_at = clock.elapsed_seconds

func _record_remote_support() -> void:
	process_store.add(ProcessDataType.new({"id": "relay_support", "device_id": "workstation_b", "process_name": "relay_support.exe", "user_name": "support.agent", "publisher": "Northstar Support Systems", "file_path": "C:/Program Files/Northstar Support/relay_support.exe", "started_at": clock.elapsed_seconds, "classification": "Observed", "has_network_activity": true, "description": "Authorized corporate remote-support session from the approved support relay. Maintenance window is pending contextual review."}))
	_record("remote_support_session", "remote_session_observed", "Access Monitor", "Workstation B", "Workstation B accepted a remote session outside its usual local activity pattern.", 0.35, "Review", "workstation_b")
	_record("remote_support_alert", "alert_created", "Access Monitor", "Workstation B", "Workstation B accepted a remote session outside its usual local activity pattern.", 0.35, "Review", "workstation_b", {"title": "Unusual remote session", "priority": "Review", "context_kind": "contextual"})
	observation_changed.emit("workstation_b", "Anomaly observed")
	remote_support_started.emit(clock.elapsed_seconds)

func prevent_escalation() -> void:
	escalation_prevented = true

func _record_file_server_attempt() -> void:
	attacker.execute("discover_file_server")
	if not attacker.execute("attempt_authentication"):
		return
	if not identity_context.observe_suspicious_attempt():
		return
	_record("file_server_attempt_wsa", "suspicious_access_attempt", "Workstation A", "File Server", "Workstation A initiated an unusual authentication attempt toward File Server.", 0.72, "Attention", "workstation_a")
	_record("file_server_attempt_fs", "suspicious_access_attempt", "Workstation A", "File Server", "Unusual authentication attempt from Workstation A was observed at the server boundary.", 0.72, "Attention", "file_server")
	_record("alert_updated_escalation", "alert_updated", "Network Sensor", "Workstation A", "Alert confidence increased after the suspicious access attempt.", 0.72, "Attention", "workstation_a")
	suspicious_access_attempt.emit(clock.elapsed_seconds)
	escalation_started_at = clock.elapsed_seconds

func _record_file_server_session() -> void:
	if not attacker.execute("establish_session"):
		return
	if not identity_context.establish_suspicious_session():
		_record("file_server_session_blocked", "authentication_blocked", "Identity Monitor", "File Server", "The File Server session could not be established because the observed credential was invalid.", 0.72, "Normal", "file_server")
		return
	_record("file_server_session", "unauthorized_session_established", "Workstation A", "File Server", "An unauthorized session was established at File Server.", 0.78, "Attention", "file_server")
	observation_changed.emit("file_server", "Anomaly observed")
	file_server_session_established.emit(clock.elapsed_seconds)
	session_started_at = clock.elapsed_seconds

func _record_abnormal_transfer() -> void:
	if not attacker.execute("start_transfer"):
		return
	if not identity_context.begin_transfer():
		_record("abnormal_transfer_blocked", "transfer_blocked", "Identity Monitor", "File Server", "Abnormal transfer did not begin because no suspicious File Server session remained active.", 0.72, "Normal", "file_server")
		return
	_record("abnormal_transfer", "abnormal_file_transfer", "File Server", "External", "An abnormal file transfer began from File Server.", 0.86, "Attention", "file_server")
	abnormal_transfer_started.emit(clock.elapsed_seconds)

func _record(id: String, event_type: String, source: String, target: String, summary: String, confidence: float, severity: String, device_id: String, extra: Dictionary = {}) -> void:
	event_log.record(SimulationEventType.new({"id": id, "timestamp": clock.elapsed_seconds, "event_type": event_type, "source": source, "target": target, "summary": summary, "additional_data": extra, "visible_to_player": true, "confidence": confidence, "visual_severity": severity, "related_device_id": device_id}))
