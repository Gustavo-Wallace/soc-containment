class_name DetailsPanel
extends Control

var current: DeviceData

func show_device(data: DeviceData) -> void:
	current = data
	queue_redraw()

func clear_device() -> void:
	current = null
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Visuals.SURFACE, true)
	draw_line(Vector2(0, 0), Vector2(0, size.y), Color(Visuals.CONNECTION, 0.75), 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(26, 37), "DEVICE DETAILS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Visuals.MUTED_TEXT)
	if current == null:
		draw_string(font, Vector2(26, 90), "No device selected", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Visuals.TEXT)
		draw_multiline_string(font, Vector2(26, 118), "Select a device in the network map to inspect its operational context.", HORIZONTAL_ALIGNMENT_LEFT, size.x - 52, 14, -1, Visuals.MUTED_TEXT)
		return
	draw_string(font, Vector2(26, 86), current.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Visuals.TEXT)
	draw_string(font, Vector2(26, 112), current.category.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Visuals.OPERATIONAL)
	var rows := [["OPERATIONAL ROLE", current.operational_role], ["NETWORK ZONE", current.zone], ["STATE", current.operational_state], ["ADDRESS", current.address], ["IMPORTANCE", current.importance]]
	var y := 154.0
	for row: Array in rows:
		draw_string(font, Vector2(26, y), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Visuals.MUTED_TEXT)
		draw_string(font, Vector2(26, y + 20), row[1], HORIZONTAL_ALIGNMENT_LEFT, size.x - 52, 15, Visuals.TEXT)
		y += 53.0
	draw_string(font, Vector2(26, y + 5), "DESCRIPTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Visuals.MUTED_TEXT)
	draw_multiline_string(font, Vector2(26, y + 24), current.description, HORIZONTAL_ALIGNMENT_LEFT, size.x - 52, 14, -1, Visuals.TEXT)
