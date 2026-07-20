class_name ReportOverlay
extends Control

const EventLogType = preload("res://scripts/event_log.gd")
const IncidentStateType = preload("res://scripts/incident_state.gd")
const VisualStyle = preload("res://scripts/visuals.gd")
const EvidenceStoreType = preload("res://scripts/evidence_store.gd")
const BusinessFlowType = preload("res://scripts/business_flow.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const IdentityContextType = preload("res://scripts/identity_context.gd")

signal restart_requested

var event_log: EventLogType
var incident_state: IncidentStateType
var outcome := ""
var restart_button: Button
var evidence_store: EvidenceStoreType
var business_flow: BusinessFlowType
var alert_system: AlertSystemType
var identity_context: IdentityContextType

func _ready() -> void:
	restart_button = Button.new()
	restart_button.text = "RESTART INCIDENT"
	restart_button.position = Vector2(832, 615)
	restart_button.size = Vector2(170, 34)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(restart_button)

func show_report(value: String, log_value: EventLogType, state_value: IncidentStateType, evidence_value: EvidenceStoreType, business_value: BusinessFlowType, alerts_value: AlertSystemType, identity_value: IdentityContextType) -> void:
	outcome = value
	event_log = log_value
	incident_state = state_value
	evidence_store = evidence_value
	business_flow = business_value
	alert_system = alerts_value
	identity_context = identity_value
	visible = true
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(VisualStyle.BACKGROUND, 0.88), true)
	var panel := Rect2(180, 48, 840, 624)
	draw_rect(panel, VisualStyle.SURFACE, true)
	draw_rect(panel, VisualStyle.CONNECTION, false, 1.2)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(214, 92), "INCIDENT REPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(214, 126), outcome, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, VisualStyle.SELECTION if outcome == "Successful Containment" else VisualStyle.AMBER)
	draw_string(font, Vector2(214, 151), _outcome_summary(), HORIZONTAL_ALIGNMENT_LEFT, 750, 13, VisualStyle.TEXT)
	draw_string(font, Vector2(214, 188), "IMPACT: " + incident_state.operational_impact.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(214, 225), "OBSERVED INCIDENT CHAIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VisualStyle.MUTED_TEXT)
	var y := 250.0
	for event in event_log.events:
		if not event.visible_to_player:
			continue
		draw_string(font, Vector2(220, y), _format_time(event.timestamp), HORIZONTAL_ALIGNMENT_LEFT, 38, 9, VisualStyle.MUTED_TEXT)
		draw_string(font, Vector2(268, y), event.summary, HORIZONTAL_ALIGNMENT_LEFT, 710, 10, VisualStyle.TEXT)
		y += 16.0
		if y > 442.0:
			break
	draw_string(font, Vector2(214, 462), "RESPONSE ASSESSMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VisualStyle.MUTED_TEXT)
	draw_multiline_string(font, Vector2(214, 474), _response_assessment(), HORIZONTAL_ALIGNMENT_LEFT, 750, 12, 2, VisualStyle.TEXT)
	draw_string(font, Vector2(214, 525), "INVESTIGATION QUALITY: " + _investigation_quality(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(214, 545), "Evidence: " + _evidence_titles(), HORIZONTAL_ALIGNMENT_LEFT, 750, 10, VisualStyle.TEXT)
	draw_string(font, Vector2(214, 579), "IDENTITY RESPONSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VisualStyle.MUTED_TEXT)
	draw_multiline_string(font, Vector2(214, 591), _identity_response(), HORIZONTAL_ALIGNMENT_LEFT, 460, 10, 2, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(700, 525), "BUSINESS CONTINUITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(700, 544), "%s • %d completed • %d missed" % [business_flow.state, business_flow.completed_runs, business_flow.missed_runs], HORIZONTAL_ALIGNMENT_LEFT, 280, 10, VisualStyle.TEXT)
	draw_string(font, Vector2(700, 561), "Downtime: %.1fs" % business_flow.downtime_seconds, HORIZONTAL_ALIGNMENT_LEFT, 280, 10, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(700, 579), "ALERT TRIAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	draw_multiline_string(font, Vector2(700, 591), _alert_triage(), HORIZONTAL_ALIGNMENT_LEFT, 280, 10, 2, VisualStyle.TEXT)

func _outcome_summary() -> String:
	if outcome == "Successful Containment":
		return "Workstation A was isolated before the File Server access attempt. The server was preserved."
	if outcome == "Partial Containment":
		return "Immediate activity was interrupted, but residual exposure or incomplete investigation remains."
	return "An abnormal file transfer began after the File Server was reached without timely containment."

func _response_assessment() -> String:
	if incident_state.action_used == null:
		return "No defensive response completed before the abnormal transfer began."
	return "%s completed at %s. The response occurred %s escalation and caused %s operational impact." % [incident_state.action_used.title, _format_time(incident_state.containment_completed_at), "after" if incident_state.escalation_occurred else "before", incident_state.operational_impact]

func _findings() -> String:
	if incident_state.session_established:
		return "A suspicious File Server session was established from Workstation A."
	return "update_bridge.exe was unverified and associated with recurring external activity."

func _evidence_titles() -> String:
	if evidence_store.evidence.is_empty():
		return "None collected."
	var titles: PackedStringArray = []
	for item in evidence_store.evidence:
		titles.append(item.title)
	return ", ".join(titles)

func _investigation_quality() -> String:
	if evidence_store.evidence.size() >= 2:
		return "STRONG — multiple relevant observations collected"
	if evidence_store.evidence.size() == 1:
		return "SUPPORTED — one investigation completed"
	return "LIMITED — no investigation completed"

func _unresolved() -> String:
	var questions: PackedStringArray = []
	if not evidence_store.has("process_profile"):
		questions.append("Executable properties remain unknown")
	if not evidence_store.has("external_communication"):
		questions.append("External destination and cadence remain unclear")
	questions.append("Initial execution mechanism and possible persistence")
	return "; ".join(questions)

func _alert_triage() -> String:
	if alert_system == null:
		return "Unresolved Alert — remote session was not reviewed."
	var alert := alert_system.alert_for_device("workstation_b")
	if alert == null or alert.state != "Benign":
		return "Unresolved Alert — the remote-session alert remained open."
	if alert.triage_status == "Verified Benign":
		return "Verified Benign — context was reviewed before closure."
	return "Unsupported Closure — classified benign before its context was verified."

func _identity_response() -> String:
	if identity_context == null or identity_context.suspicious_attempt_state == "None":
		return "No suspicious identity use was observed."
	var reset_text := "Credential remained active." if not identity_context.credentials_reset else "Credential reset; legitimate local session interrupted."
	var session_text := "File Server session: %s." % identity_context.suspicious_session_state
	var exposure_text := " Possible exposure occurred before revocation." if identity_context.exposure_before_revocation else ""
	return "finance.analyst from Workstation A targeted File Server. %s %s%s" % [reset_text, session_text, exposure_text]

func _format_time(value: float) -> String:
	var seconds := int(value)
	return "%02d:%02d" % [int(float(seconds) / 60.0), seconds % 60]
