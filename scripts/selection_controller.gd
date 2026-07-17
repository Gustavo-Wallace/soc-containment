class_name SelectionController
extends Node

signal selection_changed(data: DeviceData)
signal selection_cleared

var current: DeviceData

func select(data: DeviceData) -> void:
	if current == data:
		return
	current = data
	selection_changed.emit(data)

func clear() -> void:
	if current == null:
		return
	current = null
	selection_cleared.emit()
