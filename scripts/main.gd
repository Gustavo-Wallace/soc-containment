extends Control

const CLOCK_SCRIPT := preload("res://scripts/simulation_clock.gd")
const EVENT_LOG_SCRIPT := preload("res://scripts/event_log.gd")
const PROCESS_STORE_SCRIPT := preload("res://scripts/process_store.gd")
const ALERT_SYSTEM_SCRIPT := preload("res://scripts/alert_system.gd")
const INCIDENT_SEQUENCE_SCRIPT := preload("res://scripts/incident_sequence.gd")

@onready var network_view: NetworkView = $Content/NetworkView
@onready var details_panel: DetailsPanel = $DetailsPanel
@onready var reset_button: Button = $TopBar/ResetButton
@onready var status_label: Label = $TopBar/Status
@onready var status_dot: ColorRect = $TopBar/StatusDot
@onready var time_label: Label = $TopBar/SimulationTime
@onready var pause_button: Button = $TopBar/PauseButton
@onready var speed_1_button: Button = $TopBar/Speed1Button
@onready var speed_2_button: Button = $TopBar/Speed2Button
@onready var alert_tray: AlertTray = $Content/AlertTray

var clock: SimulationClock
var event_log: EventLog
var process_store: ProcessStore
var alert_system: AlertSystem
var incident_sequence: IncidentSequence

func _ready() -> void:
	_create_simulation_systems()
	network_view.device_selected.connect(details_panel.show_device)
	network_view.selection_cleared.connect(details_panel.clear_device)
	reset_button.pressed.connect(network_view.reset_view)
	pause_button.pressed.connect(clock.toggle_pause)
	speed_1_button.pressed.connect(func() -> void: clock.set_speed(1.0))
	speed_2_button.pressed.connect(func() -> void: clock.set_speed(2.0))
	clock.time_changed.connect(_update_time)
	clock.paused_changed.connect(_update_pause_button)
	clock.speed_changed.connect(_update_speed_buttons)
	alert_system.alert_created.connect(_on_alert_created)
	alert_tray.alert_opened.connect(_open_alert)
	incident_sequence.observation_changed.connect(network_view.set_observed_state)
	incident_sequence.unusual_route_changed.connect(network_view.set_unusual_route)
	details_panel.configure(event_log, process_store)
	incident_sequence.start()

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
	pause_button.text = "RESUME" if is_paused else "PAUSE"

func _update_speed_buttons(multiplier: float) -> void:
	speed_1_button.modulate = Visuals.SELECTION if is_equal_approx(multiplier, 1.0) else Color.WHITE
	speed_2_button.modulate = Visuals.SELECTION if is_equal_approx(multiplier, 2.0) else Color.WHITE

func _on_alert_created(alert: AlertData) -> void:
	alert_tray.show_alert(alert)
	status_label.text = "ANOMALY DETECTED"
	status_dot.color = Visuals.AMBER
	_update_speed_buttons(clock.speed_multiplier)

func _open_alert(alert: AlertData) -> void:
	network_view.focus_and_select(alert.related_device_id)
	status_label.text = "INVESTIGATION ACTIVE"
	status_dot.color = Visuals.SELECTION
