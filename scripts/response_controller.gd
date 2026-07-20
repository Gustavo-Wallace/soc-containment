class_name ResponseController
extends Node

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const ResponseActionType = preload("res://scripts/response_action.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")
const EvidenceStoreType = preload("res://scripts/evidence_store.gd")
const EvidenceDataType = preload("res://scripts/evidence_data.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")
const RecoveryContextType = preload("res://scripts/recovery_context.gd")

signal action_started(action: ResponseActionType)
signal action_progressed(action: ResponseActionType, progress: float, remaining_seconds: float)
signal action_completed(action: ResponseActionType)
signal impact_changed(impact: String)
signal process_terminated(device_id: String)
signal device_isolated(device_id: String)
signal support_alert_closed(device_id: String)
signal credentials_reset
signal connectivity_restored

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var alert_system: AlertSystemType
var active_action: ResponseActionType
var action_started_at := 0.0
var operational_impact := "None"
var evidence_store: EvidenceStoreType
var support_evidence_store: EvidenceStoreType
var identity_context: IdentityContextType
var recovery_context: RecoveryContextType

func configure(clock_value: SimulationClockType, log_value: EventLogType, store_value: ProcessStoreType, alerts_value: AlertSystemType, evidence_value: EvidenceStoreType, support_evidence_value: EvidenceStoreType, identity_value: IdentityContextType, recovery_value: RecoveryContextType) -> void:
	clock = clock_value
	event_log = log_value
	process_store = store_value
	alert_system = alerts_value
	evidence_store = evidence_value
	support_evidence_store = support_evidence_value
	identity_context = identity_value
	recovery_context = recovery_value
	clock.time_changed.connect(_on_time_changed)

func actions_for_process(process_id: String, device_id: String, observed_state: String) -> Array[ResponseActionType]:
	var actions: Array[ResponseActionType] = []
	if process_id == "relay_support" and device_id == "workstation_b":
		if not support_evidence_store.has("approved_remote_support"):
			actions.append(ResponseActionType.new({"id": "review_session_context", "title": "Review Session Context", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 3.0, "impact": "None", "benefit": "Verifies the publisher, approved source, maintenance window and support ticket.", "limitation": "The alert remains open until triage is chosen.", "consequence": "No operational impact; the primary incident keeps progressing."}))
		var support_alert := alert_system.alert_for_device(device_id)
		if support_alert != null and support_alert.state != "Benign":
			var reviewed := support_alert.reviewed
			actions.append(ResponseActionType.new({"id": "close_benign", "title": "Close as Benign", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 0.1, "impact": "None", "benefit": "Closes this contextual alert without affecting the incident case.", "limitation": "Evidence supports this classification." if reviewed else "The session context has not been verified. Closing now will be recorded as an unsupported classification.", "consequence": "The Workstation B attention marker is cleared; the authorized session may finish normally."}))
			actions.append(ResponseActionType.new({"id": "keep_open", "title": "Keep Open", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 0.1, "impact": "None", "benefit": "Leaves the contextual alert available for later review.", "limitation": "No classification is recorded.", "consequence": "No operational impact and no activity is restarted."}))
		return actions
	if process_id != "update_bridge" or device_id != "workstation_a":
		return actions
	var process := process_store.find(process_id, device_id)
	if process == null:
		return actions
	if not evidence_store.has("process_profile"):
		actions.append(ResponseActionType.new({"id": "analyze_process", "title": "Analyze Process", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 4.0, "impact": "None", "benefit": "Examines preserved process properties and behavior.", "limitation": "Does not interrupt the process.", "consequence": "No operational impact."}))
	if not evidence_store.has("external_communication") and observed_state != "Isolated" and process.classification != "Terminated":
		actions.append(ResponseActionType.new({"id": "trace_connection", "title": "Trace Connection", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 5.0, "impact": "None", "benefit": "Correlates the recurring connection with its observed route.", "limitation": "Does not block traffic.", "consequence": "No operational impact."}))
	if identity_context.suspicious_attempt_state != "None" and not identity_context.credentials_reset:
		actions.append(ResponseActionType.new({"id": "reset_credentials", "title": "Reset Credentials", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 4.0, "impact": "Low", "benefit": "Invalidates the observed credential and revokes associated sessions.", "limitation": "Does not remove the process or software from the workstation.", "consequence": "finance.analyst's legitimate local session will be interrupted."}))
	if recovery_context.contained_at >= 0.0:
		if recovery_context.persistence_state == "Hidden":
			actions.append(ResponseActionType.new({"id": "validate_persistence", "title": "Validate Persistence", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 5.0, "impact": "None", "benefit": "Reveals startup persistence and its ability to restart the process.", "limitation": "Does not remove the persistence.", "consequence": "Residual restart risk remains until removal."}))
		elif recovery_context.persistence_state == "Detected":
			actions.append(ResponseActionType.new({"id": "remove_persistence", "title": "Remove Persistence", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 3.0, "impact": "None", "benefit": "Removes BridgeSync Maintenance and prevents future restarts.", "limitation": "Does not restore network connectivity.", "consequence": "The startup mechanism is eradicated."}))
		if recovery_context.isolated:
			var restore_reason := recovery_context.can_restore(identity_context)
			if restore_reason == "":
				actions.append(ResponseActionType.new({"id": "restore_connectivity", "title": "Restore Connectivity", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 4.0, "impact": "None", "benefit": "Restores legitimate connectivity and Finance Document Sync.", "limitation": "Requires no active process, identity session, or persistence.", "consequence": "Workstation A returns to normal network operation."}))
			else:
				actions.append(ResponseActionType.new({"id": "restore_blocked", "title": "Restore Connectivity (Blocked)", "target_device_id": device_id, "target_process_id": process_id, "duration_seconds": 0.1, "impact": "None", "benefit": "Unavailable until recovery requirements are met.", "limitation": restore_reason, "consequence": "Connectivity remains isolated."}))
	if observed_state == "Isolated" or process.classification == "Terminated":
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
	var event_type := "investigation_started" if action.id.begins_with("analyze") or action.id.begins_with("trace") or action.id.begins_with("review") else "response_started"
	_record(event_type, "%s started: %s." % ["Investigation" if event_type == "investigation_started" else "Defensive action", action.title], action.target_device_id, "Attention")
	action_started.emit(action)
	return true

func _on_time_changed(time_value: float) -> void:
	if active_action == null:
		return
	var elapsed := time_value - action_started_at
	var progress := clampf(elapsed / maxf(active_action.duration_seconds, 0.1), 0.0, 1.0)
	action_progressed.emit(active_action, progress, maxf(0.0, active_action.duration_seconds - elapsed))
	if progress >= 1.0:
		_complete_active_action()

func _complete_active_action() -> void:
	var completed := active_action
	active_action = null
	if completed.id == "analyze_process":
		evidence_store.add(EvidenceDataType.new({"id": "process_profile", "title": "Unverified process profile", "source": "Process Analysis", "timestamp": clock.elapsed_seconds, "device_id": completed.target_device_id, "confidence": "Moderate", "summary": "Unrecognized publisher and uncommon local execution path.", "facts": PackedStringArray(["Publisher not recognized", "Path outside workstation baseline", "Started shortly before external connection", "Absent from known device profile"])}))
		_record("investigation_completed", "Process analysis completed; unverified profile evidence created.", completed.target_device_id, "Normal")
	elif completed.id == "trace_connection":
		evidence_store.add(EvidenceDataType.new({"id": "external_communication", "title": "Recurring external communication", "source": "Connection Trace", "timestamp": clock.elapsed_seconds, "device_id": completed.target_device_id, "confidence": "Moderate", "summary": "Workstation A → Firewall → endpoint ext-gateway-17.", "facts": PackedStringArray(["Originated at Workstation A", "Traversed Firewall", "Reached unrecognized endpoint ext-gateway-17", "Repeated outside normal profile"])}))
		_record("investigation_completed", "Connection trace completed; recurring external communication evidence created.", completed.target_device_id, "Normal")
	elif completed.id == "review_session_context":
		support_evidence_store.add(EvidenceDataType.new({"id": "approved_remote_support", "title": "Approved remote support session", "source": "Session Context Review", "timestamp": clock.elapsed_seconds, "device_id": completed.target_device_id, "confidence": "High", "summary": "Northstar Support Systems session matched the approved maintenance window and corporate support relay.", "facts": PackedStringArray(["Publisher recognized: Northstar Support Systems", "Valid signature verified", "Origin is on the corporate authorized support list", "Approved maintenance window and ticket SR-2048", "No activity outside the support scope observed"])}))
		var support_alert := alert_system.alert_for_device(completed.target_device_id)
		if support_alert != null:
			support_alert.reviewed = true
			alert_system.alert_updated.emit(support_alert)
		_record("investigation_completed", "Session context verified; approved remote support evidence created.", completed.target_device_id, "Normal")
	elif completed.id == "close_benign":
		alert_system.close_as_benign(completed.target_device_id)
		_record("alert_triaged", "Remote support alert was closed as benign.", completed.target_device_id, "Normal")
		support_alert_closed.emit(completed.target_device_id)
	elif completed.id == "keep_open":
		_record("alert_triage", "Remote support alert was kept open for later review.", completed.target_device_id, "Normal")
	elif completed.id == "reset_credentials":
		identity_context.reset_credentials()
		alert_system.update_current("Monitoring", 0.72, "Credentials were reset and File Server sessions revoked; update_bridge.exe remains active.")
		_set_impact("Low")
		_record("credentials_reset", "finance.analyst credentials were reset. update_bridge.exe remains active on Workstation A.", completed.target_device_id, "Attention")
		credentials_reset.emit()
	elif completed.id == "validate_persistence":
		recovery_context.validate()
		evidence_store.add(EvidenceDataType.new({"id": "unauthorized_startup_task", "title": "Unauthorized startup task", "source": "Persistence Validation", "timestamp": clock.elapsed_seconds, "device_id": completed.target_device_id, "confidence": "High", "summary": "BridgeSync Maintenance can restart update_bridge.exe.", "facts": PackedStringArray(["Startup task: BridgeSync Maintenance", "Associated process: update_bridge.exe", "Origin: unknown", "Restart capability confirmed"])}))
		_record("persistence_validated", "Persistence validation completed; BridgeSync Maintenance was detected.", completed.target_device_id, "Attention")
	elif completed.id == "remove_persistence":
		recovery_context.remove()
		_record("persistence_removed", "BridgeSync Maintenance was removed.", completed.target_device_id, "Normal")
	elif completed.id == "restore_connectivity":
		recovery_context.restore()
		_record("connectivity_restored", "Workstation A connectivity and Finance Document Sync were restored.", completed.target_device_id, "Normal")
		connectivity_restored.emit()
	elif completed.id == "restore_blocked":
		_record("recovery_blocked", "Connectivity restoration remains blocked: %s" % completed.limitation, completed.target_device_id, "Attention")
	elif completed.id == "terminate_process":
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
