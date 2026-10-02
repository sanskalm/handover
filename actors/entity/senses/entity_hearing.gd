extends Node
class_name EntityHearing

signal heard(pos: Vector3, strength: float)

var entity: Entity = null


func _ready() -> void:
	Events.noise_emitted.connect(_on_noise_emitted)


func _on_noise_emitted(e: NoiseEvent):
	if entity == null:
		return
	var dist := entity.global_position.distance_to(e.position)
	if dist > e.loudness:
		return

	var from := entity.global_position
	var to := e.position
	var space_state := entity.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var blocked := not space_state.intersect_ray(query).is_empty()

	var effective_dist := dist * 1.8 if blocked else dist
	if effective_dist > e.loudness:
		return

	var strength: float = 1.0 - clampf(effective_dist / e.loudness, 0.0, 1.0)
	heard.emit(e.position, strength)
	entity.perception.on_noise(strength, e.position)
