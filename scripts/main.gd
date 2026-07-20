extends Control

const CLOCK_SCRIPT := preload("res://scripts/simulation_clock.gd")
const EVENT_LOG_SCRIPT := preload("res://scripts/event_log.gd")
const PROCESS_STORE_SCRIPT := preload("res://scripts/process_store.gd")
const ALERT_SYSTEM_SCRIPT := preload("res://scripts/alert_system.gd")
const INCIDENT_SEQUENCE_SCRIPT := preload("res://scripts/incident_sequence.gd")
const NetworkViewType = preload("res://scripts/network_view.gd")
const DetailsPanelType = preload("res://scripts/details_panel.gd")
const AlertTrayType = preload("res://scripts/alert_tray.gd")
const SimulationClockType = preload("res://scripts/simulation_clock.gd")
const EventLogType = preload("res://scripts/event_log.gd")
const ProcessStoreType = preload("res://scripts/process_store.gd")
const AlertSystemType = preload("res://scripts/alert_system.gd")
const IncidentSequenceType = preload("res://scripts/incident_sequence.gd")
const AlertDataType = preload("res://scripts/alert_data.gd")
const VisualStyle = preload("res://scripts/visuals.gd")

@onready var network_view: NetworkViewType = $Content/NetworkView
@onready var details_panel: DetailsPanelType = $DetailsPanel
@onready var reset_button: Button = $TopBar/ResetButton
@onready var status_label: Label = $TopBar/Status
@onready var status_dot: ColorRect = $TopBar/StatusDot
@onready var time_label: Label = $TopBar/SimulationTime
@onready var pause_button: Button = $TopBar/PauseButton
@onready var speed_1_button: Button = $TopBar/Speed1Button
@onready var speed_2_button: Button = $TopBar/Speed2Button
@onready var alert_tray: AlertTrayType = $Content/AlertTray

var clock: SimulationClockType
var event_log: EventLogType
var process_store: ProcessStoreType
var alert_system: AlertSystemType
var incident_sequence: IncidentSequenceType

func _ready() -> void:
	_create_simulation_systems()
	network_view.device_selected.connect(details_panel.show_device)
	network_view.selection_cleared.connect(details_panel.clear_device)
	reset_button.pressed.connect(network_view.reset_view)
	pause_button.pressed.connect(clock.pause)
	speed_1_button.pressed.connect(func() -> void: clock.set_speed(1.0))
	speed_2_button.pressed.connect(func() -> void: clock.set_speed(2.0))
	clock.time_changed.connect(_update_time)
	clock.paused_changed.connect(_update_pause_button)
	clock.speed_changed.connect(_update_speed_buttons)
	clock.time_changed.connect(network_view.set_simulation_time)
	alert_system.alert_created.connect(_on_alert_created)
	alert_tray.alert_opened.connect(_open_alert)
	incident_sequence.observation_changed.connect(network_view.set_observed_state)
	incident_sequence.unusual_route_changed.connect(network_view.set_unusual_route)
	details_panel.configure(event_log, process_store)
	incident_sequence.start()
	_update_time_mode()

func _create_simulation_systems() -> void:
	var systems := Node.new()
	systems.name = "SimulationSystems"
	add_child(systems)
	clock = CLOCK_SCRIPT.new()
	event_log = EVENT_LOG_SCRIPT.new()
	process_store = PROCESS_STORE_SCRIPT.new()
	alert_system = ALERT_SYSTEM_SCRIPT.new()
	incident_sequence = INCIDENT_SEQUENCE_SCRIPT.new()
	systems.add_child(clock)
	systems.add_child(event_log)
	systems.add_child(process_store)
	systems.add_child(alert_system)
	systems.add_child(incident_sequence)
	alert_system.configure(event_log)
	incident_sequence.configure(clock, event_log, process_store)

func _update_time(_time_value: float) -> void:
	time_label.text = clock.formatted_time()

func _update_pause_button(is_paused: bool) -> void:
	_update_time_mode()

func _update_speed_buttons(multiplier: float) -> void:
	_update_time_mode()

func _update_time_mode() -> void:
	_set_time_button_state(pause_button, clock.is_paused, "PAUSE")
	_set_time_button_state(speed_1_button, not clock.is_paused and is_equal_approx(clock.speed_multiplier, 1.0), "1×")
	_set_time_button_state(speed_2_button, not clock.is_paused and is_equal_approx(clock.speed_multiplier, 2.0), "2×")

func _set_time_button_state(button: Button, active: bool, base_text: String) -> void:
	button.text = "◆ " + base_text if active else base_text
	button.add_theme_color_override("font_color", VisualStyle.TEXT if active else VisualStyle.MUTED_TEXT)
	button.add_theme_color_override("font_hover_color", VisualStyle.TEXT)
	button.add_theme_stylebox_override("normal", _time_button_style(active, false))
	button.add_theme_stylebox_override("hover", _time_button_style(active, true))

func _time_button_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(VisualStyle.SELECTION, 0.20 if active else (0.15 if hovered else 0.05))
	style.border_color = VisualStyle.SELECTION if active else Color(VisualStyle.CONNECTION, 0.7 if hovered else 0.4)
	style.set_border_width_all(2 if active else 1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	return style

func _on_alert_created(alert: AlertDataType) -> void:
	alert_tray.show_alert(alert)
	status_label.text = "ANOMALY DETECTED"
	status_dot.color = VisualStyle.AMBER
	_update_speed_buttons(clock.speed_multiplier)

func _open_alert(alert: AlertDataType) -> void:
	network_view.focus_and_select(alert.related_device_id)
	status_label.text = "INVESTIGATION ACTIVE"
	status_dot.color = VisualStyle.SELECTION
