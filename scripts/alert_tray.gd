class_name AlertTray
extends Control

signal alert_opened(alert: AlertData)

var current_alert: AlertData
var emphasis := 0.0

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func show_alert(alert: AlertData) -> void:
	current_alert = alert
	visible = true
	emphasis = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	if emphasis > 0.0:
		emphasis = maxf(0.0, emphasis - delta * 0.45)
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if current_alert != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		alert_opened.emit(current_alert)
		accept_event()

func _draw() -> void:
	if current_alert == null:
		return
	var border := Visuals.AMBER
	draw_rect(Rect2(Vector2.ZERO, size), Color(Visuals.SURFACE_ALT, 0.98), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(border, 0.72 + emphasis * 0.28), false, 1.4 + emphasis)
	draw_colored_polygon(PackedVector2Array([Vector2(18, 16), Vector2(28, 34), Vector2(8, 34)]), border)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(42, 28), "ATTENTION  •  OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, border)
	draw_string(font, Vector2(16, 57), current_alert.title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 16, Visuals.TEXT)
	draw_string(font, Vector2(16, 78), "%s  •  %s  •  %d%%" % [_format_time(current_alert.timestamp), current_alert.source, int(current_alert.confidence * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 11, Visuals.MUTED_TEXT)
	draw_string(font, Vector2(16, 99), "Workstation A — select to investigate", HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 12, Visuals.TEXT)

func _format_time(value: float) -> String:
	var seconds := int(value)
	return "%02d:%02d" % [seconds / 60, seconds % 60]
