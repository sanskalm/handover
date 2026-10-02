class_name EntityStateChase
extends State

const CATCH_DISTANCE: float = 1.2
const LOST_SIGHT_GRACE: float = 4.0

var last_known_pos: Vector3
var last_known_velocity: Vector3 = Vector3.ZERO
var lost_sight_timer: float = 0.0


func enter(data: Dictionary = { }) -> void:
	var e := owner_node as Entity
	last_known_pos = data.get("pos", e.global_position)
	last_known_velocity = Vector3.ZERO
	lost_sight_timer = 0.0
	e.go_to(last_known_pos)
	Events.entity_state_changed.emit(&"chase")


func physics_process(delta: float) -> void:
	var e := owner_node as Entity
	var can_see := e.vision.can_see_player_now()

	if can_see:
		e.go_to(e.player.global_position)
	else:
		lost_sight_timer += delta

	e.move_along_path(e.chase_speed, delta)

	if can_see and e.global_position.distance_to(e.player.global_position) <= CATCH_DISTANCE:
		Events.player_caught.emit()
		return

	if (
		(not can_see and e.navigation_agent.is_navigation_finished())
		or lost_sight_timer >= LOST_SIGHT_GRACE
	):
		transition_requested.emit(
			&"investigate",
			{ "pos": e.player.global_position, "vel": last_known_velocity },
		)


func handle_event(_event: StringName, _data: Dictionary = { }) -> void:
	pass
