class_name ConnectionLayer
extends Control

var points: Dictionary = {}
var links: Array[PackedStringArray] = []
var selected_id := ""

func configure(device_list: Array[DeviceData], link_list: Array[PackedStringArray]) -> void:
	links = link_list
	for device: DeviceData in device_list:
		points[device.id] = device.position
	queue_redraw()

func set_selected(id: String) -> void:
	selected_id = id
	queue_redraw()

func _draw() -> void:
	for link: PackedStringArray in links:
		var a: Vector2 = points[link[0]]
		var b: Vector2 = points[link[1]]
		var highlighted := selected_id == link[0] or selected_id == link[1]
		var color := Visuals.CONNECTION_SELECTED if highlighted else Visuals.CONNECTION
		var line_width := 2.1 if highlighted else 1.35
		draw_line(a, b, color, line_width, true)
		# restrained endpoint ticks give links a deliberate technical feel
		var direction := (b - a).normalized()
		draw_line(a + direction * 40, a + direction * 51, Color(color, 0.55), 1.0)
		draw_line(b - direction * 51, b - direction * 40, Color(color, 0.55), 1.0)
