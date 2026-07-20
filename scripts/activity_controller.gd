class_name ActivityController
extends Control

const DeviceDataType = preload("res://scripts/device_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

var points: Dictionary = {}
var links: Array[PackedStringArray] = []
var simulation_time := 0.0
var pulse_schedule := [0, 2, 3, 1, 4]
var unusual_route_active := false

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
		var a: Vector2 = points[link[0]]
		var b: Vector2 = points[link[1]]
		var t := age / 1.15
		var point := a.lerp(b, t)
		draw_circle(point, 5.0, Color(VisualStyle.PULSE, 0.16))
		draw_circle(point, 2.2, VisualStyle.PULSE)
	if unusual_route_active:
		_draw_unusual_route()

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
