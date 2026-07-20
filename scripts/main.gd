extends Control

const CLOCK_SCRIPT := preload("res://scripts/simulation_clock.gd")
const EVENT_LOG_SCRIPT := preload("res://scripts/event_log.gd")
const PROCESS_STORE_SCRIPT := preload("res://scripts/process_store.gd")
const ALERT_SYSTEM_SCRIPT := preload("res://scripts/alert_system.gd")
const INCIDENT_SEQUENCE_SCRIPT := preload("res://scripts/incident_sequence.gd")
const NetworkViewType = preload("res://scripts/network_view.gd")
const DetailsPanelType = preload("res://scripts/details_panel.gd")
const AlertTrayType = preload("res://scripts/alert_tray.gd")
const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const IncidentSequenceType = preload("res://scripts/incident_sequence.gd")
const AlertDataType = preload("res://scripts/alert_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")
const RESPONSE_CONTROLLER_SCRIPT := preload("res://scripts/response_controller.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")
const ResponseActionType = preload("res://scripts/response_action.gd")
const INCIDENT_STATE_SCRIPT := preload("res://scripts/incident_state.gd")
const IncidentStateType = preload("res://scripts/incident_state.gd")
const ReportOverlayType = preload("res://scripts/report_overlay.gd")
const EVIDENCE_STORE_SCRIPT := preload("res://scripts/evidence_store.gd")
const EvidenceStoreType = preload("res://scripts/evidence_store.gd")
const EvidenceDataType = preload("res://scripts/evidence_data.gd")
const BUSINESS_FLOW_SCRIPT := preload("res://scripts/business_flow.gd")
const BusinessFlowType = preload("res://scripts/business_flow.gd")
const IDENTITY_CONTEXT_SCRIPT := preload("res://scripts/identity_context.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")

@onready var network_view: NetworkViewType = $Content/NetworkView
@onready var details_panel: DetailsPanelType = $DetailsPanel
@onready var reset_button: Button = $TopBar/ResetButton
@onready var status_label: Label = $TopBar/Status
@onready var status_dot: ColorRect = $TopBar/StatusDot
@onready var time_label: Label = $TopBar/SimulationTime
@onready var pause_button: Button = $TopBar/PauseButton
@onready var speed_1_button: Button = $TopBar/Speed1Button
@onready var speed_2_button: Button = $TopBar/Speed2Button
@onready var alert_tray: AlertTrayType = $Content/AlertTray
@onready var impact_label: Label = $TopBar/ImpactLabel
@onready var report_overlay: ReportOverlayType = $ReportOverlay
@onready var business_label: Label = $Content/BusinessStatus

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var alert_system: AlertSystemType
var incident_sequence: IncidentSequenceType
var response_controller: ResponseControllerType
var incident_state: IncidentStateType
var evidence_store: EvidenceStoreType
var support_evidence_store: EvidenceStoreType
var business_flow: BusinessFlowType
var identity_context: IdentityContextType

func _ready() -> void:
	_create_simulation_systems()
	network_view.device_selected.connect(details_panel.show_device)
	network_view.selection_cleared.connect(details_panel.clear_device)
	reset_button.pressed.connect(network_view.reset_view)
	pause_button.pressed.connect(clock.pause)
	speed_1_button.pressed.connect(func() -> void: clock.set_speed(1.0))
	speed_2_button.pressed.connect(func() -> void: clock.set_speed(2.0))
	clock.time_changed.connect(_update_time)
	clock.paused_changed.connect(_update_pause_button)
	clock.speed_changed.connect(_update_speed_buttons)
	clock.time_changed.connect(network_view.set_simulation_time)
	alert_system.alert_created.connect(_on_alert_created)
	alert_system.alert_updated.connect(alert_tray.update_alert)
	alert_tray.alert_opened.connect(_open_alert)
	incident_sequence.observation_changed.connect(network_view.set_observed_state)
	incident_sequence.unusual_route_changed.connect(network_view.set_unusual_route)
	incident_sequence.suspicious_access_attempt.connect(_on_suspicious_access_attempt)
	incident_sequence.file_server_session_established.connect(_on_file_server_session)
	incident_sequence.abnormal_transfer_started.connect(_on_abnormal_transfer)
	incident_sequence.remote_support_started.connect(network_view.start_remote_support)
	business_flow.sync_started.connect(network_view.start_business_sync)
	business_flow.sync_missed.connect(_on_business_sync_missed)
	business_flow.flow_changed.connect(_update_business_status)
	incident_sequence.suspicious_access_attempt.connect(_on_escalation_evidence)
	response_controller.action_completed.connect(_on_action_completed)
	response_controller.process_terminated.connect(_on_process_terminated)
	response_controller.device_isolated.connect(_on_device_isolated)
	response_controller.support_alert_closed.connect(_on_support_alert_closed)
	response_controller.credentials_reset.connect(_on_credentials_reset)
	response_controller.impact_changed.connect(_on_impact_changed)
	incident_state.report_requested.connect(_on_report_requested)
	report_overlay.restart_requested.connect(_restart_incident)
	details_panel.configure(event_log, process_store, response_controller, incident_state)
	incident_sequence.start()
	_update_time_mode()

func _create_simulation_systems() -> void:
	var systems := Node.new()
	systems.name = "SimulationSystems"
	add_child(systems)
	clock = CLOCK_SCRIPT.new()
	event_log = EVENT_LOG_SCRIPT.new()
	process_store = PROCESS_STORE_SCRIPT.new()
	alert_system = ALERT_SYSTEM_SCRIPT.new()
	incident_sequence = INCIDENT_SEQUENCE_SCRIPT.new()
	response_controller = RESPONSE_CONTROLLER_SCRIPT.new()
	incident_state = INCIDENT_STATE_SCRIPT.new()
	evidence_store = EVIDENCE_STORE_SCRIPT.new()
	support_evidence_store = EVIDENCE_STORE_SCRIPT.new()
	business_flow = BUSINESS_FLOW_SCRIPT.new()
	identity_context = IDENTITY_CONTEXT_SCRIPT.new()
	systems.add_child(clock)
	systems.add_child(event_log)
	systems.add_child(process_store)
	systems.add_child(alert_system)
	systems.add_child(incident_sequence)
	systems.add_child(response_controller)
	systems.add_child(incident_state)
	systems.add_child(evidence_store)
	systems.add_child(support_evidence_store)
	systems.add_child(business_flow)
	systems.add_child(identity_context)
	alert_system.configure(event_log)
	identity_context.configure(clock, event_log)
	incident_sequence.configure(clock, event_log, process_store, identity_context)
	response_controller.configure(clock, event_log, process_store, alert_system, evidence_store, support_evidence_store, identity_context)
	incident_state.configure(clock, event_log)
	business_flow.configure(clock, event_log)

func _update_time(_time_value: float) -> void:
	time_label.text = clock.formatted_time()

func _update_pause_button(is_paused: bool) -> void:
	_update_time_mode()
	_update_business_status()

func _update_speed_buttons(multiplier: float) -> void:
	_update_time_mode()

func _update_time_mode() -> void:
	_set_time_button_state(pause_button, clock.is_paused, "PAUSE")
	_set_time_button_state(speed_1_button, not clock.is_paused and is_equal_approx(clock.speed_multiplier, 1.0), "1×")
	_set_time_button_state(speed_2_button, not clock.is_paused and is_equal_approx(clock.speed_multiplier, 2.0), "2×")

func _set_time_button_state(button: Button, active: bool, base_text: String) -> void:
	button.text = "◆ " + base_text if active else base_text
	button.add_theme_color_override("font_color", VisualStyle.TEXT if active else VisualStyle.MUTED_TEXT)
	button.add_theme_color_override("font_hover_color", VisualStyle.TEXT)
	button.add_theme_stylebox_override("normal", _time_button_style(active, false))
	button.add_theme_stylebox_override("hover", _time_button_style(active, true))

func _time_button_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(VisualStyle.SELECTION, 0.20 if active else (0.15 if hovered else 0.05))
	style.border_color = VisualStyle.SELECTION if active else Color(VisualStyle.CONNECTION, 0.7 if hovered else 0.4)
	style.set_border_width_all(2 if active else 1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	return style

func _on_alert_created(alert: AlertDataType) -> void:
	alert_tray.show_alert(alert)
	if alert.context_kind != "incident":
		return
	status_label.text = "ANOMALY DETECTED"
	status_dot.color = VisualStyle.AMBER
	_update_speed_buttons(clock.speed_multiplier)
	incident_state.begin_investigating()

func _open_alert(alert: AlertDataType) -> void:
	network_view.focus_and_select(alert.related_device_id)
	if alert.context_kind != "incident":
		return
	status_label.text = "INVESTIGATION ACTIVE"
	status_dot.color = VisualStyle.SELECTION

func _on_process_terminated(_device_id: String) -> void:
	network_view.set_unusual_route(false)
	status_label.text = "ACTIVITY SUPPRESSED"
	status_dot.color = VisualStyle.AMBER

func _on_device_isolated(device_id: String) -> void:
	network_view.isolate_device(device_id)
	business_flow.set_isolated(true)
	status_label.text = "DEVICE CONTAINED"
	status_dot.color = VisualStyle.MUTED_TEXT

func _on_action_completed(action: ResponseActionType) -> void:
	if action.target_device_id != "workstation_a":
		return
	if action.id == "terminate_process" or action.id == "isolate_device":
		incident_sequence.prevent_escalation()
		incident_state.register_containment(action, response_controller.operational_impact)

func _on_impact_changed(impact: String) -> void:
	impact_label.text = "IMPACT: " + impact.to_upper()
	impact_label.tooltip_text = "Low: small local interruption." if impact == "Low" else ("Medium: finance workstation unavailable." if impact == "Medium" else "No operational impact.")

func _on_suspicious_access_attempt(started_at: float) -> void:
	network_view.start_escalation_route(started_at)
	alert_system.update_current("Open", 0.72, "Suspicious access attempt toward File Server observed.")
	status_label.text = "SUSPICIOUS ACCESS ATTEMPT"
	status_dot.color = VisualStyle.AMBER
	incident_state.mark_escalated()

func _on_escalation_evidence(_started_at: float) -> void:
	evidence_store.add(EvidenceDataType.new({"id": "file_server_access", "title": "Unusual file server access", "source": "Network Sensor", "timestamp": clock.elapsed_seconds, "device_id": "file_server", "confidence": "Moderate", "summary": "Workstation A initiated an unusual authentication attempt toward File Server.", "facts": PackedStringArray(["Route passed through Firewall", "Attempt targeted File Server", "Activity was outside the workstation profile"])}))
	evidence_store.add(EvidenceDataType.new({"id": "suspicious_credential_use", "title": "Suspicious credential use", "source": "Identity Monitor", "timestamp": clock.elapsed_seconds, "device_id": "workstation_a", "confidence": "Moderate", "summary": "finance.analyst was used from Workstation A during update_bridge.exe activity; misuse is suspected but not confirmed.", "facts": PackedStringArray(["Account: finance.analyst", "Origin: Workstation A", "Destination: File Server", "Timing coincides with update_bridge.exe", "Pattern differs from normal account use"])}))

func _on_file_server_session(started_at: float) -> void:
	network_view.start_escalation_route(started_at)
	alert_system.update_current("Open", 0.78, "Unauthorized File Server session observed.")
	status_label.text = "FILE SERVER SESSION OBSERVED"
	status_dot.color = VisualStyle.AMBER
	incident_state.mark_session_established()

func _on_abnormal_transfer(_started_at: float) -> void:
	status_label.text = "ABNORMAL TRANSFER DETECTED"
	status_dot.color = VisualStyle.AMBER
	incident_state.mark_failed()

func _on_report_requested(outcome: String) -> void:
	clock.pause()
	report_overlay.show_report(outcome, event_log, incident_state, evidence_store, business_flow, alert_system, identity_context)

func _on_support_alert_closed(device_id: String) -> void:
	network_view.set_observed_state(device_id, "Normal")

func _on_credentials_reset() -> void:
	network_view.set_observed_state("file_server", "Normal")
	incident_state.register_identity_reset()

func _restart_incident() -> void:
	get_tree().reload_current_scene()

func _on_business_sync_missed(_timestamp: float) -> void:
	business_label.text = "FINANCE SYNC: INTERRUPTED • RUN MISSED"

func _update_business_status() -> void:
	var last_value := "--:--" if business_flow.last_execution < 0.0 else "%02d:%02d" % [int(float(int(business_flow.last_execution)) / 60.0), int(business_flow.last_execution) % 60]
	business_label.text = "FINANCE DOCUMENT SYNC • %s • LAST %s • NEXT %02d:%02d" % [business_flow.state.to_upper(), last_value, int(float(int(business_flow.next_execution)) / 60.0), int(business_flow.next_execution) % 60]
