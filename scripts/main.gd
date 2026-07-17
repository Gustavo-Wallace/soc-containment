extends Control

@onready var network_view: NetworkView = $Content/NetworkView
@onready var details_panel: DetailsPanel = $DetailsPanel
@onready var reset_button: Button = $TopBar/ResetButton

func _ready() -> void:
	network_view.device_selected.connect(details_panel.show_device)
	network_view.selection_cleared.connect(details_panel.clear_device)
	reset_button.pressed.connect(network_view.reset_view)
