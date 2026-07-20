class_name RecoveryContext
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal process_restart_attempted(online: bool)

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var persistence_state := "Hidden"
var contained_at := -1.0
var isolated := false
var restart_attempted := false
var restored := false

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType) -> void:
	clock = clock_value
	event_log = log_value
	process_store = store_value
	clock.time_changed.connect(_on_time_changed)

func mark_contained(is_isolated: bool) -> void:
	contained_at = clock.elapsed_seconds
	isolated = is_isolated

func validate() -> void:
	persistence_state = "Detected"
	_record("persistence_detected", "BridgeSync Maintenance startup task was detected; it could restart update_bridge.exe.")

func remove() -> void:
	persistence_state = "Removed"
	_record("persistence_removed", "BridgeSync Maintenance startup task was removed.")

func can_restore(identity_context) -> String:
	var process = process_store.find("update_bridge", "workstation_a")
	if process != null and process.classification != "Terminated":
		return "update_bridge.exe is still active."
	if persistence_state != "Removed":
		return "BridgeSync Maintenance must be removed first."
	if identity_context.suspicious_session_active or identity_context.suspicious_attempt_state == "Pending":
		return "Suspicious identity activity is still active or pending."
	if identity_context.suspicious_attempt_state != "None" and not identity_context.credentials_reset:
		return "Observed identity risk must be reset or revoked first."
	return ""

func restore() -> void:
	isolate(false)
	restored = true
	_record("connectivity_restored", "Workstation A connectivity was restored after eradication checks.")

func isolate(value: bool) -> void:
	isolated = value

func _on_time_changed(time_value: float) -> void:
	if contained_at < 0.0 or restart_attempted or persistence_state == "Removed" or time_value < contained_at + 8.0:
		return
	restart_attempted = true
	var process = process_store.find("update_bridge", "workstation_a")
	if process == null or process.classification != "Terminated":
		return
	process.classification = "Unverified"
	process.has_network_activity = not isolated
	process.description = "BridgeSync Maintenance restarted the process after containment."
	_record("persistence_restart_attempt", "BridgeSync Maintenance attempted to restart update_bridge.exe; %s." % ("isolation blocked external communication" if isolated else "external communication resumed"))
	process_restart_attempted.emit(not isolated)

func _record(event_id: String, summary: String) -> void:
	event_log.record(SimulationEventType.new({"id": event_id + "_" + str(int(clock.elapsed_seconds * 10.0)), "timestamp": clock.elapsed_seconds, "event_type": event_id, "source": "Recovery Validation", "target": "Workstation A", "summary": summary, "additional_data": {}, "visible_to_player": true, "confidence": 0.76, "visual_severity": "Attention", "related_device_id": "workstation_a"}))
