extends CanvasLayer

@export var perception: EntityPerception

@onready var suspicion_bar: ProgressBar = $PanelContainer/VBoxContainer/SuspicionBar
@onready var confidence_bar: ProgressBar = $PanelContainer/VBoxContainer/ConfidenceBar
@onready var state_label: Label = $PanelContainer/VBoxContainer/AIState


func _process(_delta: float) -> void:
	if not is_instance_valid(perception):
		return

	suspicion_bar.value = perception.suspicion
	confidence_bar.value = perception.confidence

	var sus_thr := perception.get_investigate_threshold()
	var conf_thr := perception.get_chase_threshold()

	if perception.is_chasing():
		state_label.text = "State: CHASE"
	elif perception.confidence >= conf_thr:
		state_label.text = "State: CHASE (reacting...)"
	elif perception.suspicion >= sus_thr:
		state_label.text = "State: INVESTIGATE (reacting...)"
	elif perception.suspicion > 15.0:
		state_label.text = "State: UNEASY"
	else:
		state_label.text = "State: IDLE"

	state_label.text += "\nAlert: %d%%  |  Inv @ %.0f  Chase @ %.0f" % [
		perception.alertness * 100.0,
		sus_thr,
		conf_thr,
	]
