extends RefCounted
class_name NoiseEvent

enum Type {
	FOOTSTEP,
	DISTRACTION,
	ENVIRONMENT,
	VOICE,
}

var position: Vector3 = Vector3.ZERO
var loudness: float = 1.0
var type: Type = Type.FOOTSTEP


func _init(p_pos: Vector3, p_loudness: float, p_type: Type = Type.FOOTSTEP) -> void:
	position = p_pos
	loudness = p_loudness
	type = p_type
