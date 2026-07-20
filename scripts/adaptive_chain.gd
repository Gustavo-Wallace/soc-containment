class_name AdaptiveChain
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")
const RecoveryContextType = preload("res://scripts/recovery_context.gd")
const AttackerStateType = preload("res://scripts/attacker_state.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal local_discovery_completed
signal local_staging_completed
signal local_transfer_started
signal local_transfer_completed

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var identity_context: IdentityContextType
var recovery_context: RecoveryContextType
var attacker: AttackerStateType
var adaptation_used := false
var phase := "Idle"
var phase_started_at := -1.0
var staged_data := false
var transfer_active := false

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType, identity_value: IdentityContextType, recovery_value: RecoveryContextType, attacker_value: AttackerStateType) -> void:
	add_to_group("adaptive_chain")
	clock = clock_value
	event_log = log_value
	process_store = store_value
	identity_context = identity_value
	recovery_context = recovery_value
	attacker = attacker_value
	clock.time_changed.connect(_on_time_changed)

func _on_time_changed(time_value: float) -> void:
	if phase == "Idle" and _can_adapt():
		adaptation_used = true
		phase = "Discovering"
		phase_started_at = time_value
		attacker.objective = "Collect locally accessible finance data"
		attacker.current_action = "Discover Local Finance Data"
		attacker.chain_log.append("%05.1f | route blocked: credential invalidated; selected local data collection" % time_value)
		_record("local_discovery_started", "Workstation A began accessing local finance documents at an unusual rate.", "Attention")
		return
	if phase == "Discovering" and time_value - phase_started_at >= 4.0:
		phase = "Staging"
		phase_started_at = time_value
		attacker.current_action = "Stage Local Data"
		_record("local_discovery_completed", "Multiple local finance documents were accessed in a short interval.", "Attention")
		local_discovery_completed.emit()
	elif phase == "Staging" and time_value - phase_started_at >= 4.0:
		phase = "Transferring"
		phase_started_at = time_value
		staged_data = true
		transfer_active = true
		attacker.current_action = "Transfer Staged Data"
		_record("local_staging_completed", "Local documents were prepared for external transfer.", "Attention")
		local_staging_completed.emit()
		local_transfer_started.emit()
	elif phase == "Transferring" and time_value - phase_started_at >= 6.0:
		transfer_active = false
		phase = "Completed"
		attacker.current_action = "Local data transfer completed"
		_record("local_transfer_completed", "Possible exposure: staged local finance data was transferred externally.", "Attention")
		local_transfer_completed.emit()

func cancel_network_activity() -> void:
	if phase == "Discovering" or phase == "Staging" or phase == "Transferring":
		transfer_active = false
		phase = "Cancelled"
		attacker.current_action = "Local route cancelled"
		_record("local_route_cancelled", "Local data collection route was interrupted by containment.", "Normal")

func _can_adapt() -> bool:
	if adaptation_used or not identity_context.credentials_reset or recovery_context.isolated:
		return false
	var process = process_store.find("update_bridge", "workstation_a")
	return process != null and process.classification != "Terminated" and process.has_network_activity and not identity_context.transfer_started

func _record(event_id: String, summary: String, severity: String) -> void:
	event_log.record(SimulationEventType.new({"id": event_id + "_" + str(int(clock.elapsed_seconds * 10.0)), "timestamp": clock.elapsed_seconds, "event_type": event_id, "source": "Network Sensor", "target": "Workstation A", "summary": summary, "additional_data": {}, "visible_to_player": true, "confidence": 0.78, "visual_severity": severity, "related_device_id": "workstation_a"}))
