class_name NetworkView
extends Control

signal device_selected(data: DeviceData)
signal selection_cleared

const DEVICE_SCENE := preload("res://scenes/device_node.tscn")
const CONNECTION_SCENE := preload("res://scenes/connection_layer.tscn")
const ACTIVITY_SCENE := preload("res://scenes/activity_controller.tscn")

var camera: Control
var connections: ConnectionLayer
var activity: ActivityController
var selection_controller: SelectionController
var device_nodes: Dictionary = {}
var selected_id := ""
var camera_scale := 1.0
var pan_active := false
var pan_origin := Vector2.ZERO

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	selection_controller = SelectionController.new()
	selection_controller.selection_changed.connect(_apply_selection)
	selection_controller.selection_cleared.connect(_remove_selection)
	add_child(selection_controller)
	camera = Control.new()
	camera.name = "NetworkCanvas"
	camera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camera)
	connections = CONNECTION_SCENE.instantiate()
	connections.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera.add_child(connections)
	activity = ACTIVITY_SCENE.instantiate()
	activity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera.add_child(activity)
	var devices := NetworkData.create_devices()
	var links := NetworkData.create_links()
	connections.configure(devices, links)
	activity.configure(devices, links)
	for data: DeviceData in devices:
		var node: DeviceNode = DEVICE_SCENE.instantiate()
		node.configure(data)
		node.device_selected.connect(_select_device)
		camera.add_child(node)
		device_nodes[data.id] = node
	call_deferred("reset_view")

func _draw() -> void:
	var grid_step := 48.0
	for x: int in range(0, int(size.x) + 1, int(grid_step)):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Visuals.GRID, 1.0)
	for y: int in range(0, int(size.y) + 1, int(grid_step)):
		draw_line(Vector2(0, y), Vector2(size.x, y), Visuals.GRID, 1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			pan_active = event.pressed
			pan_origin = event.position
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(camera_scale * 1.12, event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(camera_scale / 1.12, event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clear_selection()
	elif event is InputEventMouseMotion and pan_active:
		camera.position += event.position - pan_origin
		pan_origin = event.position
		_clamp_camera()
		accept_event()

func _set_zoom(value: float, focus: Vector2) -> void:
	var next := clampf(value, 0.68, 1.45)
	if is_equal_approx(next, camera_scale):
		return
	var world_focus := (focus - camera.position) / camera_scale
	camera_scale = next
	camera.scale = Vector2.ONE * camera_scale
	camera.position = focus - world_focus * camera_scale
	_clamp_camera()

func _clamp_camera() -> void:
	camera.position.x = clampf(camera.position.x, -480.0, 240.0)
	camera.position.y = clampf(camera.position.y, -270.0, 190.0)

func _select_device(data: DeviceData) -> void:
	selection_controller.select(data)

func _apply_selection(data: DeviceData) -> void:
	if selected_id != "" and device_nodes.has(selected_id):
		(device_nodes[selected_id] as DeviceNode).set_selected(false)
	selected_id = data.id
	(device_nodes[selected_id] as DeviceNode).set_selected(true)
	connections.set_selected(selected_id)
	device_selected.emit(data)

func clear_selection() -> void:
	selection_controller.clear()

func _remove_selection() -> void:
	if selected_id != "" and device_nodes.has(selected_id):
		(device_nodes[selected_id] as DeviceNode).set_selected(false)
	selected_id = ""
	connections.set_selected("")
	selection_cleared.emit()

func reset_view() -> void:
	camera_scale = 1.0
	camera.scale = Vector2.ONE
	camera.position = Vector2(0, 0)
