class_name DetailsPanel
extends Control

const DETAILS_CONTENT_SCENE := preload("res://scenes/details_content.tscn")
const DetailsContentType = preload("res://scripts/details_content.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const DeviceDataType = preload("res://scripts/device_data.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")

var scroll_container: ScrollContainer
var details_content: DetailsContentType

func _ready() -> void:
	scroll_container = ScrollContainer.new()
	scroll_container.name = "InvestigationScroll"
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)
	details_content = DETAILS_CONTENT_SCENE.instantiate()
	scroll_container.add_child(details_content)

func configure(log_value: EventLogType, store_value: ProcessStoreType, response_value: ResponseControllerType) -> void:
	details_content.configure(log_value, store_value, response_value)

func show_device(data: DeviceDataType) -> void:
	details_content.show_device(data)
	scroll_container.scroll_vertical = 0

func clear_device() -> void:
	details_content.clear_device()
	scroll_container.scroll_vertical = 0
