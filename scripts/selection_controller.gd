class_name SelectionController
extends Node

const DeviceDataType = preload("res://scripts/device_data.gd")

signal selection_changed(data: DeviceDataType)
signal selection_cleared

var current: DeviceDataType

func select(data: DeviceDataType) -> void:
	if current == data:
		return
	current = data
	selection_changed.emit(data)

func clear() -> void:
	if current == null:
		return
	current = null
	selection_cleared.emit()
