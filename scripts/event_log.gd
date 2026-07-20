class_name EventLog
extends Node

signal event_recorded(event: SimulationEvent)

var events: Array[SimulationEvent] = []

func record(event: SimulationEvent) -> void:
	events.append(event)
	event_recorded.emit(event)

func visible_events_for_device(device_id: String, limit: int = 3) -> Array[SimulationEvent]:
	var result: Array[SimulationEvent] = []
	for index: int in range(events.size() - 1, -1, -1):
		var event := events[index]
		if event.visible_to_player and event.related_device_id == device_id:
			result.append(event)
			if result.size() >= limit:
				break
	result.reverse()
	return result
