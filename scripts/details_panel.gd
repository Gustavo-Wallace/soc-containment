class_name DetailsPanel
extends Control

const DETAILS_CONTENT_SCENE := preload("res://scenes/details_content.tscn")
const DetailsContentType = preload("res://scripts/details_content.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const DeviceDataType = preload("res://scripts/device_data.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")
const IncidentStateType = preload("res://scripts/incident_state.gd")

var scroll_container: ScrollContainer
var details_content: DetailsContentType
var incident_state: IncidentStateType
var finalize_button: Button
var finalize_hint: Label

func _ready() -> void:
	scroll_container = ScrollContainer.new()
	scroll_container.name = "InvestigationScroll"
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)
	details_content = DETAILS_CONTENT_SCENE.instantiate()
	scroll_container.add_child(details_content)
	finalize_button = Button.new()
	finalize_button.text = "FINALIZE INCIDENT"
	finalize_button.visible = false
	finalize_button.position = Vector2(42, size.y - 52)
	finalize_button.size = Vector2(212, 34)
	finalize_button.pressed.connect(func() -> void: incident_state.finalize_incident())
	add_child(finalize_button)
	finalize_hint = Label.new()
	finalize_hint.text = "Activity interrupted. Residual risk remains; review before finalizing."
	finalize_hint.visible = false
	finalize_hint.position = Vector2(22, size.y - 82)
	finalize_hint.size = Vector2(252, 28)
	finalize_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finalize_hint.add_theme_font_size_override("font_size", 10)
	add_child(finalize_hint)

func configure(log_value: EventLogType, store_value: ProcessStoreType, response_value: ResponseControllerType, state_value: IncidentStateType) -> void:
	details_content.configure(log_value, store_value, response_value)
	incident_state = state_value
	incident_state.finalize_available.connect(func() -> void: finalize_button.visible = true; finalize_hint.visible = true)

func show_device(data: DeviceDataType) -> void:
	details_content.show_device(data)
	scroll_container.scroll_vertical = 0

func clear_device() -> void:
	details_content.clear_device()
	scroll_container.scroll_vertical = 0
