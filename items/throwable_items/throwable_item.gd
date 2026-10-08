class_name ThrowableItem
extends RigidBody3D

@export var friction_mult: float = 0.95
@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio
@onready var interactable: Interactable = $Interactable

@onready var timer: Timer = $Timer


func _ready():
	body_entered.connect(_on_body_entered)
	timer.wait_time = 5.0
	timer.timeout.connect(freeze_physics)
	interactable.interacted_with.connect(_on_interacted)


func throw(throw_dir: Vector3, throw_force: float = 3.0):
	interactable.process_mode = Node.PROCESS_MODE_INHERIT
	freeze = false

	var throw_vector = throw_dir.normalized() * throw_force
	apply_central_impulse(throw_vector)

	timer.start()


func freeze_physics():
	freeze = true


func _on_interacted(player: Player) -> void:
	if player.try_hold(self):
		interactable.process_mode = Node.PROCESS_MODE_DISABLED
		freeze = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			if state.get_contact_local_normal(i).dot(Vector3.UP) > 0.5:
				state.linear_velocity.x *= friction_mult
				state.linear_velocity.z *= friction_mult


func _on_body_entered(_b: Node):
	var e := NoiseEvent.new(global_position, 50, NoiseEvent.Type.DISTRACTION)
	Events.noise_emitted.emit(e)
	impact_audio.play()
