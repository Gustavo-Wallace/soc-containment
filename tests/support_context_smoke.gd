extends SceneTree

const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")
const EvidenceStoreType = preload("res://scripts/evidence_store.gd")
const ProcessDataType = preload("res://scripts/process_data.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")

func _init() -> void:
	_test_unsupported_closure()
	_test_verified_closure()
	quit(0)

func _make_context() -> Array:
	var clock := SimulationClockType.new()
	var log := EventLogType.new()
	var processes := ProcessStoreType.new()
	var alerts := AlertSystemType.new()
	var controller := ResponseControllerType.new()
	var incident_evidence := EvidenceStoreType.new()
	var support_evidence := EvidenceStoreType.new()
	alerts.configure(log)
	controller.configure(clock, log, processes, alerts, incident_evidence, support_evidence)
	log.record(SimulationEventType.new({"id": "support_alert", "timestamp": 16.0, "event_type": "alert_created", "source": "Access Monitor", "target": "Workstation B", "summary": "Workstation B accepted a remote session outside its usual local activity pattern.", "additional_data": {"title": "Unusual remote session", "priority": "Review", "context_kind": "contextual"}, "visible_to_player": true, "confidence": 0.35, "visual_severity": "Review", "related_device_id": "workstation_b"}))
	processes.add(ProcessDataType.new({"id": "relay_support", "device_id": "workstation_b", "process_name": "relay_support.exe", "user_name": "support.agent", "publisher": "Northstar Support Systems", "file_path": "C:/Program Files/Northstar Support/relay_support.exe", "started_at": 16.0, "classification": "Observed", "has_network_activity": true, "description": "Authorized support."}))
	return [clock, alerts, controller, support_evidence]

func _test_unsupported_closure() -> void:
	var context := _make_context()
	var clock: SimulationClockType = context[0]
	var alerts: AlertSystemType = context[1]
	var controller: ResponseControllerType = context[2]
	var actions = controller.actions_for_process("relay_support", "workstation_b", "Anomaly observed")
	assert(controller.start(actions[1]))
	clock.elapsed_seconds = 0.2
	controller._on_time_changed(clock.elapsed_seconds)
	assert(alerts.alert_for_device("workstation_b").triage_status == "Unsupported Closure")

func _test_verified_closure() -> void:
	var context := _make_context()
	var clock: SimulationClockType = context[0]
	var alerts: AlertSystemType = context[1]
	var controller: ResponseControllerType = context[2]
	var support_evidence: EvidenceStoreType = context[3]
	var actions = controller.actions_for_process("relay_support", "workstation_b", "Anomaly observed")
	assert(controller.start(actions[0]))
	clock.elapsed_seconds = 3.1
	controller._on_time_changed(clock.elapsed_seconds)
	assert(support_evidence.has("approved_remote_support"))
	assert(not controller.evidence_store.has("approved_remote_support"))
	actions = controller.actions_for_process("relay_support", "workstation_b", "Anomaly observed")
	assert(controller.start(actions[0]))
	clock.elapsed_seconds = 3.3
	controller._on_time_changed(clock.elapsed_seconds)
	assert(alerts.alert_for_device("workstation_b").triage_status == "Verified Benign")
