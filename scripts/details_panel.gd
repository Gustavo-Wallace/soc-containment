class_name DetailsPanel
extends Control

const DETAILS_CONTENT_SCENE := preload("res://scenes/details_content.tscn")
const DetailsContentType = preload("res://scripts/details_content.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const DeviceDataType = preload("res://scripts/device_data.gd")
const ResponseControllerType = preload("res://scripts/response_controller.gd")
const IncidentStateType = preload("res://scripts/incident_state.gd")
const RecoveryContextType = preload("res://scripts/recovery_context.gd")

var scroll_container: ScrollContainer
var details_content: DetailsContentType
var incident_state: IncidentStateType
var finalize_button: Button
var finalize_hint: Label
var recovery_context: RecoveryContextType
var awaiting_residual_confirmation := false

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
	finalize_button.pressed.connect(_request_finalize)
	add_child(finalize_button)
	finalize_hint = Label.new()
	finalize_hint.text = "Activity interrupted. Residual risk remains; review before finalizing."
	finalize_hint.visible = false
	finalize_hint.position = Vector2(22, size.y - 82)
	finalize_hint.size = Vector2(252, 28)
	finalize_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finalize_hint.add_theme_font_size_override("font_size", 10)
	add_child(finalize_hint)

func configure(log_value: EventLogType, store_value: ProcessStoreType, response_value: ResponseControllerType, state_value: IncidentStateType, recovery_value: RecoveryContextType) -> void:
	details_content.configure(log_value, store_value, response_value)
	incident_state = state_value
	recovery_context = recovery_value
	incident_state.finalize_available.connect(func() -> void: finalize_button.visible = true; finalize_hint.visible = true)

func _request_finalize() -> void:
	if recovery_context != null and recovery_context.persistence_state == "Hidden" and not awaiting_residual_confirmation:
		awaiting_residual_confirmation = true
		finalize_hint.text = "Persistence has not been validated. The incident can be closed, but residual access may remain unresolved."
		finalize_button.text = "CONFIRM RESIDUAL RISK"
		return
	incident_state.finalize_incident()

func show_device(data: DeviceDataType) -> void:
	details_content.show_device(data)
	scroll_container.scroll_vertical = 0

func clear_device() -> void:
	details_content.clear_device()
	scroll_container.scroll_vertical = 0
