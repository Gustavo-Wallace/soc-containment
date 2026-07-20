class_name DeviceNode
extends Control

const DeviceDataType = preload("res://scripts/device_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

signal device_selected(data: DeviceDataType)

var data: DeviceDataType
var is_selected := false
var is_hovered := false
var activity_phase := 0.0

func configure(value: DeviceDataType) -> void:
	data = value
	position = data.position - VisualStyle.DEVICE_SIZE * 0.5
	queue_redraw()

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(func() -> void: is_hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: is_hovered = false; queue_redraw())
	gui_input.connect(_on_gui_input)

func _process(delta: float) -> void:
	activity_phase = fmod(activity_phase + delta, 1.8)
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		device_selected.emit(data)
		accept_event()

func _draw() -> void:
	if data == null:
		return
	var center := size * 0.5
	var ring_center := Vector2(center.x, 48.0)
	var is_anomalous := data.observed_state == "Anomaly observed" or data.observed_state == "Under inspection"
	var accent := VisualStyle.SELECTION if is_selected else (VisualStyle.OPERATIONAL if is_hovered else VisualStyle.CONNECTION)
	var outline_width := 2.5 if is_selected else (1.8 if is_hovered else 1.2)
	if is_selected:
		draw_circle(ring_center, 35.0, Color(VisualStyle.SELECTION, 0.10))
		draw_arc(ring_center, 35.0, 0.0, TAU, 32, VisualStyle.SELECTION, 1.3)
	if is_anomalous:
		draw_arc(ring_center, 29.0, 0.25, TAU - 0.25, 28, VisualStyle.AMBER, 1.8)
		draw_colored_polygon(PackedVector2Array([Vector2(15, 19), Vector2(24, 19), Vector2(19.5, 27)]), VisualStyle.AMBER)
	_draw_silhouette(center, accent, outline_width)
	# device name and category are intentionally part of the reusable visual
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, 91), data.display_name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 14, VisualStyle.TEXT)
	draw_string(font, Vector2(8, 107), data.category.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 10, VisualStyle.MUTED_TEXT)
	if is_anomalous:
		draw_string(font, Vector2(8, 13), "OBSERVED" if data.observed_state == "Anomaly observed" else "INSPECTING", HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 9, VisualStyle.AMBER)
	var active_alpha := 0.45 + 0.45 * sin(activity_phase * TAU / 1.8)
	draw_circle(Vector2(size.x - 20, 20), 4.0, Color(VisualStyle.OPERATIONAL, active_alpha))

func _draw_silhouette(c: Vector2, accent: Color, width: float) -> void:
	match data.kind:
		"internet":
			draw_circle(c, 26, Color(VisualStyle.SURFACE_ALT, 0.92))
			draw_arc(c, 26, 0, TAU, 32, accent, width)
			draw_arc(c, 17, 0, TAU, 28, Color(accent, 0.65), 1.0)
			draw_line(c - Vector2(26, 0), c + Vector2(26, 0), Color(accent, 0.55), 1.0)
			draw_line(c - Vector2(0, 26), c + Vector2(0, 26), Color(accent, 0.55), 1.0)
		"firewall":
			var hex := PackedVector2Array([c + Vector2(-29, 0), c + Vector2(-15, -25), c + Vector2(15, -25), c + Vector2(29, 0), c + Vector2(15, 25), c + Vector2(-15, 25)])
			draw_colored_polygon(hex, Color(VisualStyle.SURFACE_ALT, 0.96))
			draw_polyline(hex + PackedVector2Array([hex[0]]), accent, width, true)
			draw_line(c + Vector2(-16, -7), c + Vector2(16, -7), Color(accent, 0.6), 1.2)
			draw_line(c + Vector2(-16, 7), c + Vector2(16, 7), Color(accent, 0.6), 1.2)
		"workstation":
			draw_rect(Rect2(c - Vector2(29, 22), Vector2(58, 39)), Color(VisualStyle.SURFACE_ALT, 0.96), true)
			draw_rect(Rect2(c - Vector2(29, 22), Vector2(58, 39)), accent, false, width)
			draw_line(c + Vector2(0, 17), c + Vector2(0, 27), accent, width)
			draw_line(c + Vector2(-15, 27), c + Vector2(15, 27), accent, width)
		"server", "backup":
			draw_rect(Rect2(c - Vector2(23, 29), Vector2(46, 56)), Color(VisualStyle.SURFACE_ALT, 0.96), true)
			draw_rect(Rect2(c - Vector2(23, 29), Vector2(46, 56)), accent, false, width)
			for y: float in [-13.0, 1.0, 15.0]:
				draw_line(c + Vector2(-15, y), c + Vector2(11, y), Color(accent, 0.55), 1.0)
				draw_circle(c + Vector2(15, y), 2.0, accent)
			if data.kind == "backup":
				draw_arc(c + Vector2(0, -35), 10, 0, PI, 12, VisualStyle.AMBER, 1.4)
