extends Node
class_name EntityVision

@export var raycast: RayCast3D
@export var proximity_radius: float = 1.5

const INSTANT_SPOT_RANGE: float = 2.5

var max_range: float = 30.0
var fov_degrees: int = 120
var check_interval: float = 0.1
var _timer: float = 0.0

var entity: Entity = null


func _process(delta: float) -> void:
	_timer += delta
	if _timer < check_interval:
		return
	_timer = 0.0
	_evaluate()


func _evaluate() -> void:
	if DebugManager.is_invisible:
		return

	if entity == null or entity.player == null:
		return

	var player := entity.player
	var dist := entity.global_position.distance_to(player.global_position)
	if dist > max_range:
		return

	if dist <= proximity_radius and not _is_blocked(player):
		entity.perception.force_spot(player.global_position)
		return

	if not can_see_player_now():
		return

	if dist <= INSTANT_SPOT_RANGE:
		entity.perception.force_spot(player.global_position)
		return

	var to_player := (player.global_position - entity.global_position).normalized()
	var forward := -entity.global_transform.basis.z
	var angle_deg := rad_to_deg(forward.angle_to(to_player))

	var dist_factor: float = 1.0 - clampf(dist / max_range, 0.0, 1.0)
	var light_factor := _get_light_level_at(player.global_position)
	var move_factor := 1.0 if player.is_moving else 0.5
	var is_clear := angle_deg < fov_degrees * 0.3

	var strength := dist_factor * light_factor * move_factor
	entity.perception.on_vision(strength, is_clear, player.global_position)


func can_see_player_now() -> bool:
	if DebugManager.is_invisible:
		return false

	if entity == null or entity.player == null:
		return false

	var player := entity.player
	var dist := entity.global_position.distance_to(player.global_position)
	if dist > max_range:
		return false

	if not _is_in_fov(player.global_position):
		return false

	return not _is_blocked(player)


func _is_in_fov(target_pos: Vector3) -> bool:
	var to_target := (target_pos - entity.global_position).normalized()
	var forward := -entity.global_transform.basis.z
	var angle_deg := rad_to_deg(forward.angle_to(to_target))
	return angle_deg <= fov_degrees / 2.0


func _is_blocked(p: Player) -> bool:
	raycast.target_position = raycast.to_local(p.global_position)
	raycast.force_raycast_update()
	return raycast.is_colliding()


func _get_light_level_at(_pos: Vector3) -> float:
	return 1.0
