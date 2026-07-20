class_name AttackerDebugPanel
extends Panel

const AttackerStateType = preload("res://scripts/attacker_state.gd")

var attacker: AttackerStateType
var output: Label
signal close_requested

func _ready() -> void:
	position = Vector2(18, 78)
	size = Vector2(360, 300)
	var close := Button.new()
	close.text = "CLOSE DEBUG (F3)"
	close.position = Vector2(202, 10)
	close.size = Vector2(145, 28)
	close.pressed.connect(func() -> void: close_requested.emit())
	add_child(close)
	output = Label.new()
	output.position = Vector2(14, 44)
	output.size = Vector2(332, 244)
	output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output.add_theme_font_size_override("font_size", 11)
	add_child(output)

func _process(_delta: float) -> void:
	if visible and attacker != null:
		output.text = "ATTACKER DEBUG\nState: %s\nObjective: %s\nPosition: %s\nProcess active: %s\nCredential: %s (%s)\nSession: %s\nPersistence: %s\nCurrent: %s\nNext: %s\n\n%s" % [attacker.operation_state, attacker.objective, attacker.position, str(attacker.can_execute("external_communication")), "finance.analyst", "invalid" if attacker.identity_context.credentials_reset else "valid", attacker.identity_context.suspicious_session_state, attacker.recovery_context.persistence_state, attacker.current_action, attacker.next_action, "\n".join(attacker.chain_log)]
