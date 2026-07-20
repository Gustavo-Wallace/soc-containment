class_name AttackerState
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")
const RecoveryContextType = preload("res://scripts/recovery_context.gd")

var clock: SimulationClockType
var process_store: ProcessStoreType
var identity_context: IdentityContextType
var recovery_context: RecoveryContextType
var objective := "Reach and transfer File Server files"
var position := "Workstation A"
var controlled_devices := PackedStringArray(["workstation_a"])
var known_devices := PackedStringArray(["workstation_a", "firewall", "internet"])
var current_action := "Idle"
var next_action := "start_process"
var operation_state := "Active"
var completed: Dictionary = {}
var chain_log: Array[String] = []

func configure(clock_value: SimulationClockType, store_value: ProcessStoreType, identity_value: IdentityContextType, recovery_value: RecoveryContextType) -> void:
	clock = clock_value
	process_store = store_value
	identity_context = identity_value
	recovery_context = recovery_value

func can_execute(action_id: String) -> bool:
	var process = process_store.find("update_bridge", "workstation_a")
	var process_active: bool = false
	if process != null:
		process_active = process.classification != "Terminated"
	match action_id:
		"start_process": return not completed.has("start_process")
		"external_communication": return process_active and not recovery_context.isolated
		"discover_file_server": return completed.has("external_communication")
		"attempt_authentication": return process_active and completed.has("discover_file_server") and not identity_context.credentials_reset and not recovery_context.isolated
		"establish_session": return identity_context.suspicious_attempt_state == "Pending" and not identity_context.credentials_reset
		"start_transfer": return process_active and identity_context.can_start_transfer()
		"restart_process": return recovery_context.persistence_state != "Removed"
	return false

func execute(action_id: String) -> bool:
	var allowed := can_execute(action_id)
	var reason := "requirements satisfied" if allowed else _blocked_reason(action_id)
	chain_log.append("%s | %s | %s" % [_time(), action_id, "completed" if allowed else "blocked: " + reason])
	if chain_log.size() > 7:
		chain_log.pop_front()
	if not allowed:
		current_action = "Blocked: " + action_id
		next_action = _next_planned()
		return false
	completed[action_id] = true
	current_action = action_id
	position = "File Server" if action_id == "establish_session" or action_id == "start_transfer" else "Workstation A"
	if action_id == "discover_file_server" and not known_devices.has("file_server"):
		known_devices.append("file_server")
	next_action = _next_planned()
	return true

func apply_defense(defense_id: String) -> void:
	chain_log.append("%s | defense | %s" % [_time(), defense_id])
	if defense_id == "remove_persistence":
		completed["restart_process"] = true
	if defense_id == "terminate_process":
		current_action = "Process capability removed"
	next_action = _next_planned()

func _next_planned() -> String:
	for action_id in ["start_process", "external_communication", "discover_file_server", "attempt_authentication", "establish_session", "start_transfer"]:
		if not completed.has(action_id):
			return action_id
	return "operation_complete"

func _blocked_reason(action_id: String) -> String:
	if recovery_context.isolated:
		return "Workstation A is isolated"
	if identity_context.credentials_reset:
		return "credential invalidated"
	return "required offensive capability unavailable"

func _time() -> String:
	return "%05.1f" % clock.elapsed_seconds
