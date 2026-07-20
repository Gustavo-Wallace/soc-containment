class_name NetworkView
extends Control

const DeviceDataType = preload("res://scripts/device_data.gd")
const DeviceNodeType = preload("res://scripts/device_node.gd")
const ConnectionLayerType = preload("res://scripts/connection_layer.gd")
const ActivityControllerType = preload("res://scripts/activity_controller.gd")
const SelectionControllerType = preload("res://scripts/selection_controller.gd")
const NetworkDataType = preload("res://scripts/network_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

signal device_selected(data: DeviceDataType)
signal selection_cleared

const DEVICE_SCENE := preload("res://scenes/device_node.tscn")
const CONNECTION_SCENE := preload("res://scenes/connection_layer.tscn")
const ACTIVITY_SCENE := preload("res://scenes/activity_controller.tscn")

var camera: Control
var connections: ConnectionLayerType
var activity: ActivityControllerType
var selection_controller: SelectionControllerType
var device_nodes: Dictionary = {}
var selected_id := ""
var camera_scale := 1.0
var pan_active := false
var pan_origin := Vector2.ZERO

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	selection_controller = SelectionControllerType.new()
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
	var devices := NetworkDataType.create_devices()
	var links := NetworkDataType.create_links()
	connections.configure(devices, links)
	activity.configure(devices, links)
	for data: DeviceDataType in devices:
		var node: DeviceNodeType = DEVICE_SCENE.instantiate()
		node.configure(data)
		node.device_selected.connect(_select_device)
		camera.add_child(node)
		device_nodes[data.id] = node
	call_deferred("reset_view")

func _draw() -> void:
	var grid_step := 48.0
	for x: int in range(0, int(size.x) + 1, int(grid_step)):
		draw_line(Vector2(x, 0), Vector2(x, size.y), VisualStyle.GRID, 1.0)
	for y: int in range(0, int(size.y) + 1, int(grid_step)):
		draw_line(Vector2(0, y), Vector2(size.x, y), VisualStyle.GRID, 1.0)

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

func _select_device(data: DeviceDataType) -> void:
	selection_controller.select(data)

func _apply_selection(data: DeviceDataType) -> void:
	if selected_id != "" and device_nodes.has(selected_id):
		var previous: DeviceNodeType = device_nodes[selected_id]
		previous.set_selected(false)
		if previous.data.observed_state == "Under inspection":
			previous.data.observed_state = "Anomaly observed"
			previous.queue_redraw()
	selected_id = data.id
	if data.observed_state == "Anomaly observed":
		data.observed_state = "Under inspection"
		(device_nodes[selected_id] as DeviceNodeType).set_selected(true)
	connections.set_selected(selected_id)
	device_selected.emit(data)

func clear_selection() -> void:
	selection_controller.clear()

func _remove_selection() -> void:
	if selected_id != "" and device_nodes.has(selected_id):
		(device_nodes[selected_id] as DeviceNodeType).set_selected(false)
	selected_id = ""
	connections.set_selected("")
	selection_cleared.emit()

func reset_view() -> void:
	camera_scale = 1.0
	camera.scale = Vector2.ONE
	camera.position = Vector2(0, 0)

func set_observed_state(device_id: String, observed_state: String) -> void:
	if not device_nodes.has(device_id):
		return
	var node: DeviceNodeType = device_nodes[device_id]
	node.data.observed_state = observed_state
	node.queue_redraw()

func set_unusual_route(active: bool) -> void:
	activity.set_unusual_route(active)

func start_escalation_route(started_at: float) -> void:
	activity.start_escalation(started_at)

func start_business_sync(started_at: float) -> void:
	activity.start_business_sync(started_at)

func start_remote_support(started_at: float) -> void:
	activity.start_remote_support(started_at)

func isolate_device(device_id: String) -> void:
	set_observed_state(device_id, "Isolated")
	connections.set_blocked_device(device_id)
	activity.set_blocked_device(device_id)

func restore_device_connectivity(device_id: String) -> void:
	set_observed_state(device_id, "Normal")
	connections.set_blocked_device("")
	activity.set_blocked_device("")

func set_simulation_time(time_value: float) -> void:
	activity.set_simulation_time(time_value)

func focus_and_select(device_id: String) -> void:
	if not device_nodes.has(device_id):
		return
	var node: DeviceNodeType = device_nodes[device_id]
	camera.position = size * 0.5 - node.data.position * camera_scale
	_clamp_camera()
	selection_controller.select(node.data)
