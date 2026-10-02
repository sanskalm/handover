extends RigidBody3D

@export var friction_mult: float = 0.95
@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio


func _ready():
	body_entered.connect(_on_body_entered)


func throw(throw_dir: Vector3, throw_force: float = 5.0):
	freeze = false

	var throw_vector = throw_dir.normalized() * throw_force
	apply_central_impulse(throw_vector)

	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.start()
	timer.timeout.connect(queue_free)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			if state.get_contact_local_normal(i).dot(Vector3.UP) > 0.5:
				state.linear_velocity.x *= friction_mult
				state.linear_velocity.z *= friction_mult


func _on_body_entered(b: Node):
	var e := NoiseEvent.new(global_position, 50, NoiseEvent.Type.DISTRACTION)
	Events.noise_emitted.emit(e)
	impact_audio.play()
