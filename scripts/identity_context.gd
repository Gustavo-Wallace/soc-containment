class_name IdentityContext
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal identity_changed

var clock: SimulationClockType
var event_log: EventLogType
var account_name := "finance.analyst"
var credential_state := "Active"
var credential_version := 1
var local_session_state := "Active"
var suspicious_attempt_state := "None"
var suspicious_session_state := "Pending"
var suspicious_session_active := false
var transfer_active := false
var transfer_started := false
var credentials_reset := false
var exposure_before_revocation := false

func configure(clock_value: SimulationClockType, log_value: EventLogType) -> void:
	clock = clock_value
	event_log = log_value

func observe_suspicious_attempt() -> bool:
	if credentials_reset:
		suspicious_attempt_state = "Blocked"
		_record("credential_attempt_blocked", "Credential attempt for finance.analyst was blocked after reset.", "workstation_a", "Normal")
		identity_changed.emit()
		return false
	suspicious_attempt_state = "Pending"
	_record("suspicious_credential_use", "finance.analyst was used from Workstation A for unusual File Server access while update_bridge.exe was active.", "workstation_a", "Attention")
	identity_changed.emit()
	return true

func establish_suspicious_session() -> bool:
	if credentials_reset or suspicious_attempt_state == "Blocked":
		suspicious_session_state = "Blocked"
		identity_changed.emit()
		return false
	suspicious_attempt_state = "Accepted"
	suspicious_session_state = "Active"
	suspicious_session_active = true
	_record("suspicious_session_active", "A suspicious finance.analyst session became active on File Server.", "file_server", "Attention")
	identity_changed.emit()
	return true

func can_start_transfer() -> bool:
	return suspicious_session_active and suspicious_session_state == "Active"

func begin_transfer() -> bool:
	if not can_start_transfer():
		return false
	transfer_active = true
	transfer_started = true
	identity_changed.emit()
	return true

func reset_credentials() -> void:
	credentials_reset = true
	credential_version += 1
	credential_state = "Reset v%d" % credential_version
	local_session_state = "Revoked"
	if suspicious_session_active:
		suspicious_session_state = "Revoked"
		suspicious_session_active = false
	else:
		suspicious_session_state = "Blocked"
	if transfer_active:
		exposure_before_revocation = true
		transfer_active = false
	suspicious_attempt_state = "Blocked"
	_record("credentials_reset", "Credentials for finance.analyst were reset; associated sessions were revoked and the legitimate local session was interrupted.", "workstation_a", "Normal")
	_record("file_server_session_revoked", "File Server authentication session for finance.analyst was revoked by the credential reset.", "file_server", "Normal")
	identity_changed.emit()

func _record(id: String, summary: String, device_id: String, severity: String) -> void:
	event_log.record(SimulationEventType.new({"id": id + "_" + str(int(clock.elapsed_seconds * 10.0)), "timestamp": clock.elapsed_seconds, "event_type": id, "source": "Identity Monitor", "target": "File Server", "summary": summary, "additional_data": {"account": account_name, "credential_version": credential_version, "attempt": suspicious_attempt_state, "session": suspicious_session_state}, "visible_to_player": true, "confidence": 0.72, "visual_severity": severity, "related_device_id": device_id}))
