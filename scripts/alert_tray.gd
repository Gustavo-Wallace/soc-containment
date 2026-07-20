class_name AlertTray
extends Control

const AlertDataType = preload("res://scripts/alert_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

signal alert_opened(alert: AlertDataType)

var alerts: Array[AlertDataType] = []
var emphasis := 0.0
var card_rects: Array[Rect2] = []

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func show_alert(alert: AlertDataType) -> void:
	if not alerts.has(alert):
		alerts.append(alert)
	visible = true
	emphasis = 1.0
	queue_redraw()

func update_alert(alert: AlertDataType) -> void:
	if not alerts.has(alert):
		alerts.append(alert)
	queue_redraw()

func _process(delta: float) -> void:
	if emphasis > 0.0:
		emphasis = maxf(0.0, emphasis - delta * 0.45)
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	for index: int in range(card_rects.size()):
		if card_rects[index].has_point(event.position):
			alert_opened.emit(alerts[index])
			accept_event()
			return

func _draw() -> void:
	card_rects.clear()
	if alerts.is_empty():
		return
	var font := ThemeDB.fallback_font
	for index: int in range(alerts.size()):
		var alert: AlertDataType = alerts[index]
		var rect := Rect2(0, float(index) * 86.0, size.x, 80.0)
		card_rects.append(rect)
		var is_primary := alert.priority != "Review"
		var accent := VisualStyle.AMBER if is_primary else VisualStyle.SELECTION
		var alpha := 0.72 + emphasis * 0.28 if index == alerts.size() - 1 else 0.72
		draw_rect(rect, Color(VisualStyle.SURFACE_ALT, 0.98), true)
		draw_rect(rect, Color(accent, alpha), false, 1.4 if is_primary else 1.0)
		draw_string(font, rect.position + Vector2(12, 19), "%s  •  %s" % [alert.priority.to_upper(), alert.state.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent)
		draw_string(font, rect.position + Vector2(12, 40), alert.title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 14, VisualStyle.TEXT)
		draw_string(font, rect.position + Vector2(12, 58), "%s  •  %s  •  %d%%" % [_format_time(alert.timestamp), alert.source, int(alert.confidence * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, VisualStyle.MUTED_TEXT)
		var device_name := "Workstation A" if alert.related_device_id == "workstation_a" else "Workstation B"
		draw_string(font, rect.position + Vector2(12, 74), "%s — select to inspect" % device_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, VisualStyle.TEXT)

func _format_time(value: float) -> String:
	var seconds := int(value)
	return "%02d:%02d" % [int(float(seconds) / 60.0), seconds % 60]
