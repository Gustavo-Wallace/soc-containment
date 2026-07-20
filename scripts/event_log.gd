class_name EventLog
extends Node

const SimulationEventType = preload("res://scripts/simulation_event.gd")

signal event_recorded(event: SimulationEventType)

var events: Array[SimulationEventType] = []

func record(event: SimulationEventType) -> void:
	events.append(event)
	event_recorded.emit(event)

func visible_events_for_device(device_id: String, limit: int = 3) -> Array[SimulationEventType]:
	var result: Array[SimulationEventType] = []
	for index: int in range(events.size() - 1, -1, -1):
		var event: SimulationEventType = events[index]
		if event.visible_to_player and event.related_device_id == device_id:
			result.append(event)
			if result.size() >= limit:
				break
	result.reverse()
	return result
