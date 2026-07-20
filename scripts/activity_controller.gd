class_name ActivityController
extends Control

const DeviceDataType = preload("res://scripts/device_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

var points: Dictionary = {}
var links: Array[PackedStringArray] = []
var simulation_time := 0.0
var pulse_schedule := [0, 2, 3, 1, 4]
var unusual_route_active := false
var escalation_started_at := -1.0
var blocked_device_id := ""
var business_sync_started_at := -1.0
var remote_support_started_at := -1.0

func configure(device_list: Array[DeviceDataType], link_list: Array[PackedStringArray]) -> void:
	links = link_list
	for device: DeviceDataType in device_list:
		points[device.id] = device.position

func set_simulation_time(time_value: float) -> void:
	# Network traffic is simulation activity: it deliberately follows SimulationClock.
	# UI-only effects, such as alert-card emphasis, keep using their own real-time process.
	simulation_time = time_value
	queue_redraw()

func set_unusual_route(active: bool) -> void:
	unusual_route_active = active
	queue_redraw()

func set_blocked_device(device_id: String) -> void:
	blocked_device_id = device_id
	if device_id == "workstation_a":
		unusual_route_active = false
	queue_redraw()

func start_escalation(started_at: float) -> void:
	escalation_started_at = started_at
	queue_redraw()

func start_business_sync(started_at: float) -> void:
	business_sync_started_at = started_at
	queue_redraw()

func start_remote_support(started_at: float) -> void:
	remote_support_started_at = started_at
	queue_redraw()

func _draw() -> void:
	if links.is_empty():
		return
	# One pulse every 1.4 seconds, each present for 1.15 seconds.
	for offset: int in range(3):
		var cycle := int(floor(simulation_time / 1.4)) - offset
		var age := simulation_time - float(cycle) * 1.4
		if age < 0.0 or age > 1.15:
			continue
		var link: PackedStringArray = links[pulse_schedule[abs(cycle) % pulse_schedule.size()]]
		if blocked_device_id != "" and (link[0] == blocked_device_id or link[1] == blocked_device_id):
			continue
		var a: Vector2 = points[link[0]]
		var b: Vector2 = points[link[1]]
		var t := age / 1.15
		var point := a.lerp(b, t)
		draw_circle(point, 5.0, Color(VisualStyle.PULSE, 0.16))
		draw_circle(point, 2.2, VisualStyle.PULSE)
	if unusual_route_active:
		_draw_unusual_route()
	if escalation_started_at >= 0.0 and simulation_time - escalation_started_at <= 4.0:
		_draw_escalation_route()
	if business_sync_started_at >= 0.0 and simulation_time - business_sync_started_at <= 2.4 and blocked_device_id != "workstation_a":
		_draw_business_sync()
	if remote_support_started_at >= 0.0 and simulation_time - remote_support_started_at <= 7.0:
		_draw_remote_support()

func _draw_unusual_route() -> void:
	var phase := fmod(simulation_time, 1.9) / 1.9
	var workstation: Vector2 = points["workstation_a"]
	var firewall: Vector2 = points["firewall"]
	var internet: Vector2 = points["internet"]
	var first := workstation.lerp(firewall, minf(phase * 2.0, 1.0))
	var second := firewall.lerp(internet, maxf(0.0, phase * 2.0 - 1.0))
	var point := first if phase < 0.5 else second
	draw_circle(point, 6.0, Color(VisualStyle.AMBER, 0.16))
	draw_circle(point, 2.5, VisualStyle.AMBER)

func _draw_escalation_route() -> void:
	var phase := fmod(simulation_time - escalation_started_at, 2.2) / 2.2
	var workstation: Vector2 = points["workstation_a"]
	var firewall: Vector2 = points["firewall"]
	var file_server: Vector2 = points["file_server"]
	var first := workstation.lerp(firewall, minf(phase * 2.0, 1.0))
	var second := firewall.lerp(file_server, maxf(0.0, phase * 2.0 - 1.0))
	var point := first if phase < 0.5 else second
	draw_circle(point, 7.0, Color(VisualStyle.AMBER, 0.18))
	draw_circle(point, 2.8, VisualStyle.AMBER)

func _draw_business_sync() -> void:
	var phase := clampf((simulation_time - business_sync_started_at) / 2.4, 0.0, 1.0)
	var workstation: Vector2 = points["workstation_a"]
	var firewall: Vector2 = points["firewall"]
	var file_server: Vector2 = points["file_server"]
	var point := workstation.lerp(firewall, phase * 2.0) if phase < 0.5 else firewall.lerp(file_server, (phase - 0.5) * 2.0)
	draw_circle(point, 6.0, Color(VisualStyle.PULSE, 0.18))
	draw_circle(point, 2.6, VisualStyle.PULSE)

func _draw_remote_support() -> void:
	var phase := fmod(simulation_time - remote_support_started_at, 2.0) / 2.0
	var internet: Vector2 = points["internet"]
	var firewall: Vector2 = points["firewall"]
	var workstation: Vector2 = points["workstation_b"]
	var point := internet.lerp(firewall, phase * 2.0) if phase < 0.5 else firewall.lerp(workstation, (phase - 0.5) * 2.0)
	draw_circle(point, 6.0, Color(VisualStyle.SELECTION, 0.18))
	draw_circle(point, 2.5, VisualStyle.SELECTION)
