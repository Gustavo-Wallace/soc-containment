class_name IncidentState
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ResponseActionType = preload("res://scripts/response_action.gd")

signal state_changed(next_state: String)
signal finalize_available
signal report_requested(outcome: String)

var clock: SimulationClockType
var event_log: EventLogType
var current_state := "MONITORING"
var action_used: ResponseActionType
var escalation_occurred := false
var session_established := false
var containment_completed_at := -1.0
var finalize_ready_at := -1.0
var operational_impact := "None"
var credentials_reset := false
var transfer_started := false
var failure_report_at := -1.0
var report_sent := false

func configure(clock_value: SimulationClockType, log_value: EventLogType) -> void:
	clock = clock_value
	event_log = log_value
	clock.time_changed.connect(_on_time_changed)

func begin_investigating() -> void:
	_set_state("INVESTIGATING")

func mark_escalated() -> void:
	escalation_occurred = true
	_set_state("ESCALATED")

func mark_session_established() -> void:
	session_established = true
	_set_state("ESCALATED")

func register_containment(action: ResponseActionType, impact: String) -> void:
	action_used = action
	operational_impact = impact
	containment_completed_at = clock.elapsed_seconds
	finalize_ready_at = containment_completed_at + 5.0
	_set_state("POST_CONTAINMENT")

func register_identity_reset() -> void:
	credentials_reset = true
	if action_used != null and action_used.id == "terminate_process":
		operational_impact = "Low"
		containment_completed_at = clock.elapsed_seconds
		finalize_ready_at = containment_completed_at + 5.0
		_set_state("POST_CONTAINMENT")

func mark_failed() -> void:
	transfer_started = true
	failure_report_at = clock.elapsed_seconds + 5.0
	_set_state("EXPOSED")

func reopen() -> void:
	finalize_ready_at = -1.0
	_set_state("ESCALATED")

func can_finalize() -> bool:
	return current_state == "POST_CONTAINMENT" and finalize_ready_at >= 0.0 and clock.elapsed_seconds >= finalize_ready_at

func finalize_incident() -> void:
	if not can_finalize():
		return
	_set_state("RESOLVED")
	report_requested.emit(_outcome())

func _on_time_changed(_time_value: float) -> void:
	if can_finalize():
		finalize_available.emit()
	if current_state == "EXPOSED" and failure_report_at >= 0.0 and clock.elapsed_seconds >= failure_report_at and not report_sent:
		report_sent = true
		report_requested.emit("Severe Compromise")

func _outcome() -> String:
	if action_used != null and action_used.id == "isolate_device" and not escalation_occurred:
		return "Successful Containment"
	if action_used != null and action_used.id == "terminate_process" and credentials_reset and not transfer_started:
		return "Successful Containment"
	return "Partial Containment"

func _set_state(next_state: String) -> void:
	if current_state == next_state:
		return
	current_state = next_state
	state_changed.emit(next_state)
