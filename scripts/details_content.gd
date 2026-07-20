class_name DetailsContent
extends Control

const DeviceDataType = preload("res://scripts/device_data.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const ProcessDataType = preload("res://scripts/process_data.gd")
const SimulationEventType = preload("res://scripts/simulation_event.gd")
const VisualStyle = preload("res://scripts/visuals.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")
const ResponseActionType = preload("res://scripts/response_action.gd")

var current: DeviceDataType
var event_log: EventLogType
var process_store: ProcessStoreType
var selected_process: ProcessDataType
var visible_processes: Array[ProcessDataType] = []
var process_rows: Array[Rect2] = []
var response_controller: ResponseControllerType
var available_actions: Array[ResponseActionType] = []
var action_rows: Array[Rect2] = []
var pending_action: ResponseActionType
var active_action: ResponseActionType
var action_progress := 0.0
var action_remaining := 0.0
var confirm_rect := Rect2()
var cancel_rect := Rect2()

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func configure(log_value: EventLogType, store_value: ProcessStoreType, response_value: ResponseControllerType) -> void:
	event_log = log_value
	process_store = store_value
	response_controller = response_value
	event_log.event_recorded.connect(_on_event_recorded)
	process_store.process_added.connect(_on_process_added)
	response_controller.action_started.connect(_on_action_started)
	response_controller.action_progressed.connect(_on_action_progressed)
	response_controller.action_completed.connect(_on_action_completed)

func show_device(data: DeviceDataType) -> void:
	current = data
	selected_process = null
	pending_action = null
	_update_content_height()
	queue_redraw()

func clear_device() -> void:
	current = null
	selected_process = null
	pending_action = null
	_update_content_height()
	queue_redraw()

func _on_event_recorded(event: SimulationEventType) -> void:
	if current != null and event.related_device_id == current.id:
		queue_redraw()

func _on_process_added(process: ProcessDataType) -> void:
	if current != null and process.device_id == current.id:
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if current == null or not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	for index: int in range(process_rows.size()):
		if process_rows[index].has_point(event.position):
			selected_process = visible_processes[index]
			_update_content_height()
			queue_redraw()
			accept_event()
			return
	for index: int in range(action_rows.size()):
		if action_rows[index].has_point(event.position) and active_action == null:
			pending_action = available_actions[index]
			_update_content_height()
			queue_redraw()
			accept_event()
			return
	if pending_action != null and confirm_rect.has_point(event.position):
		if response_controller.start(pending_action):
			pending_action = null
		queue_redraw()
		accept_event()
		return
	if pending_action != null and cancel_rect.has_point(event.position):
		pending_action = null
		_update_content_height()
		queue_redraw()
		accept_event()

func _on_action_started(action: ResponseActionType) -> void:
	active_action = action
	action_progress = 0.0
	queue_redraw()

func _on_action_progressed(action: ResponseActionType, progress: float, remaining_seconds: float) -> void:
	active_action = action
	action_progress = progress
	action_remaining = remaining_seconds
	queue_redraw()

func _on_action_completed(_action: ResponseActionType) -> void:
	active_action = null
	action_progress = 0.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), VisualStyle.SURFACE, true)
	draw_line(Vector2(0, 0), Vector2(0, size.y), Color(VisualStyle.CONNECTION, 0.75), 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(22, 32), "DEVICE INVESTIGATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VisualStyle.MUTED_TEXT)
	if current == null:
		draw_string(font, Vector2(22, 82), "No device selected", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, VisualStyle.TEXT)
		draw_multiline_string(font, Vector2(22, 110), "Select a device in the network map to inspect its operational context.", HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 14, -1, VisualStyle.MUTED_TEXT)
		return
	draw_string(font, Vector2(22, 71), current.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, VisualStyle.TEXT)
	draw_string(font, Vector2(22, 92), current.category.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.OPERATIONAL)
	draw_string(font, Vector2(22, 118), "OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	var rows := [["ROLE", current.operational_role], ["ZONE", current.zone], ["OBSERVED", current.observed_state], ["ADDRESS", current.address], ["IMPORTANCE", current.importance]]
	var y := 139.0
	for row: Array in rows:
		draw_string(font, Vector2(22, y), row[0], HORIZONTAL_ALIGNMENT_LEFT, 72, 9, VisualStyle.MUTED_TEXT)
		var value_color := VisualStyle.AMBER if row[0] == "OBSERVED" and current.observed_state != "Normal" else VisualStyle.TEXT
		draw_string(font, Vector2(98, y), row[1], HORIZONTAL_ALIGNMENT_LEFT, size.x - 120, 11, value_color)
		y += 24.0
	_draw_observations(font, 275.0)
	_draw_processes(font, 430.0)

func _draw_observations(font: Font, y: float) -> void:
	draw_string(font, Vector2(22, y), "RECENT OBSERVATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	if event_log == null:
		return
	var observations := event_log.visible_events_for_device(current.id)
	var line_y := y + 21.0
	if observations.is_empty():
		draw_string(font, Vector2(22, line_y), "No visible observations yet.", HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 11, VisualStyle.MUTED_TEXT)
		return
	for observation: SimulationEventType in observations:
		var accent := VisualStyle.AMBER if observation.visual_severity == "Attention" else VisualStyle.OPERATIONAL
		draw_circle(Vector2(25, line_y - 4), 2.5, accent)
		draw_string(font, Vector2(34, line_y), _format_time(observation.timestamp), HORIZONTAL_ALIGNMENT_LEFT, 34, 9, VisualStyle.MUTED_TEXT)
		draw_multiline_string(font, Vector2(72, line_y - 11), observation.summary, HORIZONTAL_ALIGNMENT_LEFT, size.x - 94, 10, 2, VisualStyle.TEXT)
		line_y += 42.0

func _draw_processes(font: Font, y: float) -> void:
	process_rows.clear()
	visible_processes.clear()
	draw_string(font, Vector2(22, y), "PROCESSES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	if process_store == null:
		return
	visible_processes = process_store.get_for_device(current.id)
	var line_y := y + 22.0
	for process: ProcessDataType in visible_processes:
		var row := Rect2(18, line_y - 15, size.x - 36, 21)
		process_rows.append(row)
		var selected := selected_process == process
		if selected:
			draw_rect(row, Color(VisualStyle.SELECTION, 0.12), true)
			draw_rect(row, Color(VisualStyle.SELECTION, 0.65), false, 1.0)
		var color := VisualStyle.AMBER if process.classification == "Unverified" else VisualStyle.TEXT
		draw_string(font, Vector2(24, line_y), process.process_name, HORIZONTAL_ALIGNMENT_LEFT, 143, 11, color)
		draw_string(font, Vector2(170, line_y), process.classification, HORIZONTAL_ALIGNMENT_LEFT, 66, 10, color)
		draw_string(font, Vector2(235, line_y), "NET" if process.has_network_activity else "", HORIZONTAL_ALIGNMENT_LEFT, 35, 9, VisualStyle.MUTED_TEXT)
		line_y += 24.0
	if selected_process != null:
		_draw_process_detail(font, line_y + 8.0)
		_draw_response_actions(font, line_y + 118.0)

func _draw_process_detail(font: Font, y: float) -> void:
	draw_line(Vector2(22, y - 8), Vector2(size.x - 22, y - 8), Color(VisualStyle.CONNECTION, 0.5), 1.0)
	draw_string(font, Vector2(22, y + 4), "PROCESS DETAILS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(22, y + 20), "%s  •  %s  •  %s" % [selected_process.user_name, _format_time(selected_process.started_at), selected_process.classification], HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 10, VisualStyle.TEXT)
	draw_string(font, Vector2(22, y + 35), "Publisher: %s" % selected_process.publisher, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 10, VisualStyle.TEXT)
	draw_multiline_string(font, Vector2(22, y + 44), selected_process.file_path, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 9, 2, VisualStyle.MUTED_TEXT)
	draw_string(font, Vector2(22, y + 83), "Observed connections: %s" % ("Recurring external" if selected_process.has_network_activity else "None"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 10, VisualStyle.TEXT)
	draw_multiline_string(font, Vector2(22, y + 91), selected_process.description, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 9, 2, VisualStyle.MUTED_TEXT)

func _draw_response_actions(font: Font, y: float) -> void:
	action_rows.clear()
	available_actions.clear()
	if response_controller == null:
		return
	available_actions = response_controller.actions_for_process(selected_process.id, current.id, current.observed_state)
	if available_actions.is_empty() and active_action == null:
		return
	draw_line(Vector2(22, y - 10), Vector2(size.x - 22, y - 10), Color(VisualStyle.CONNECTION, 0.5), 1.0)
	draw_string(font, Vector2(22, y + 4), "RESPONSE ACTIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	if active_action != null:
		draw_string(font, Vector2(22, y + 25), "%s IN PROGRESS" % active_action.title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 11, VisualStyle.SELECTION)
		draw_rect(Rect2(22, y + 35, size.x - 44, 8), Color(VisualStyle.CONNECTION, 0.5), true)
		draw_rect(Rect2(22, y + 35, (size.x - 44) * action_progress, 8), VisualStyle.SELECTION, true)
		draw_string(font, Vector2(22, y + 61), "%.1fs remaining • %s impact" % [action_remaining, active_action.impact], HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 10, VisualStyle.TEXT)
		return
	var line_y := y + 27.0
	for action: ResponseActionType in available_actions:
		var row := Rect2(18, line_y - 15, size.x - 36, 57)
		action_rows.append(row)
		draw_rect(row, Color(VisualStyle.SURFACE_ALT, 0.70), true)
		draw_rect(row, Color(VisualStyle.CONNECTION, 0.55), false, 1.0)
		draw_string(font, Vector2(25, line_y), action.title, HORIZONTAL_ALIGNMENT_LEFT, 150, 12, VisualStyle.TEXT)
		draw_string(font, Vector2(180, line_y), "%ss • %s" % [int(action.duration_seconds), action.impact], HORIZONTAL_ALIGNMENT_LEFT, 80, 10, VisualStyle.AMBER)
		draw_multiline_string(font, Vector2(25, line_y + 7), action.benefit, HORIZONTAL_ALIGNMENT_LEFT, size.x - 55, 9, 2, VisualStyle.MUTED_TEXT)
		line_y += 64.0
	if pending_action != null:
		_draw_confirmation(font, line_y + 4.0)
	_draw_case_evidence(font, line_y + 154.0 if pending_action != null else line_y + 6.0)

func _draw_case_evidence(font: Font, y: float) -> void:
	draw_line(Vector2(22, y - 8), Vector2(size.x - 22, y - 8), Color(VisualStyle.CONNECTION, 0.5), 1.0)
	draw_string(font, Vector2(22, y + 4), "CASE EVIDENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VisualStyle.MUTED_TEXT)
	var store = response_controller.evidence_store
	var confidence := store.hypothesis_confidence()
	draw_string(font, Vector2(22, y + 22), "Hypothesis (%s): Workstation A may be running unauthorized software communicating externally." % confidence, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 9, VisualStyle.TEXT)
	var evidence_y := y + 40.0
	for item in store.evidence:
		draw_string(font, Vector2(22, evidence_y), "• " + item.title + " — " + item.confidence, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 10, VisualStyle.AMBER)
		evidence_y += 18.0

func _draw_confirmation(font: Font, y: float) -> void:
	draw_rect(Rect2(18, y - 14, size.x - 36, 143), Color(VisualStyle.SURFACE_ALT, 0.98), true)
	draw_rect(Rect2(18, y - 14, size.x - 36, 143), VisualStyle.AMBER, false, 1.2)
	draw_string(font, Vector2(25, y + 4), "CONFIRM %s" % pending_action.title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 11, VisualStyle.AMBER)
	draw_string(font, Vector2(25, y + 25), "Target: Workstation A • %ss • %s impact" % [int(pending_action.duration_seconds), pending_action.impact], HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 10, VisualStyle.TEXT)
	draw_multiline_string(font, Vector2(25, y + 32), pending_action.consequence, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 10, 2, VisualStyle.TEXT)
	draw_multiline_string(font, Vector2(25, y + 63), "Limitation: " + pending_action.limitation, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 9, 2, VisualStyle.MUTED_TEXT)
	confirm_rect = Rect2(25, y + 103, 116, 24)
	cancel_rect = Rect2(151, y + 103, 96, 24)
	draw_rect(confirm_rect, Color(VisualStyle.SELECTION, 0.22), true)
	draw_rect(confirm_rect, VisualStyle.SELECTION, false, 1.0)
	draw_string(font, Vector2(29, y + 120), "CONFIRM", HORIZONTAL_ALIGNMENT_LEFT, 106, 10, VisualStyle.TEXT)
	draw_rect(cancel_rect, Color(VisualStyle.SURFACE, 0.8), true)
	draw_rect(cancel_rect, Color(VisualStyle.CONNECTION, 0.8), false, 1.0)
	draw_string(font, Vector2(155, y + 120), "CANCEL", HORIZONTAL_ALIGNMENT_LEFT, 86, 10, VisualStyle.TEXT)

func _format_time(value: float) -> String:
	var seconds := int(value)
	return "%02d:%02d" % [int(float(seconds) / 60.0), seconds % 60]

func _update_content_height() -> void:
	custom_minimum_size.y = 1100.0 if selected_process != null and selected_process.id == "update_bridge" else (760.0 if selected_process != null else 662.0)
