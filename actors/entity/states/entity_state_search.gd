class_name EntityStateSearch
extends State

const SEARCH_RADIUS: float = 10.0
const MAX_POINTS: int = 4
const MAX_SEARCH_TIME: float = 20.0
const REACH_DIST: float = 2.0
const LOOK_AROUND_TIME: float = 3.0

var points: Array[Vector3] = []
var index: int = 0
var start_time: float = 0.0
var _pausing: bool = false
var _pause_timer: float = 0.0


func enter(data: Dictionary = { }) -> void:
	var e := owner_node as Entity
	var origin: Vector3 = data.get("last_pos", e.global_position)
	var search_dir: Vector3 = data.get("vel", -e.global_transform.basis.z)
	points = _generate_points(origin, search_dir)
	index = 0
	start_time = Time.get_ticks_msec() / 1000.0
	_pausing = false


func _generate_points(origin: Vector3, search_dir: Vector3) -> Array[Vector3]:
	var e := owner_node as Entity
	var result: Array[Vector3] = []
	var map_rid := e.navigation_agent.get_navigation_map()

	var forward := Vector3(search_dir.x, 0, search_dir.z).normalized()
	if forward.length_squared() == 0:
		forward = -e.global_transform.basis.z

	var base_angle := atan2(forward.z, forward.x)

	for i in range(MAX_POINTS):
		var angle_offset := randf_range(-PI / 4.0, PI / 4.0)
		var final_angle := base_angle + angle_offset
		var dir := Vector3(cos(final_angle), 0, sin(final_angle))

		var min_dist := 3.0 + (i * 2.0)
		var max_dist := clampf(min_dist + 3.0, 4.0, SEARCH_RADIUS)
		var dist := randf_range(min_dist, max_dist)

		var target_pos := origin + (dir * dist)

		var nav_point := NavigationServer3D.map_get_closest_point(map_rid, target_pos)
		result.append(nav_point)

	return result


func physics_process(delta: float) -> void:
	var e := owner_node as Entity
	var now := Time.get_ticks_msec() / 1000.0

	if index >= points.size() or now - start_time > MAX_SEARCH_TIME:
		transition_requested.emit(&"patrol", { })
		return

	if _pausing:
		e.velocity = Vector3.ZERO
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_pausing = false
			index += 1
		return

	var target: Vector3 = points[index]
	e.go_to(target)
	e.move_along_path(e.search_speed, delta)

	if e.global_position.distance_to(target) <= REACH_DIST:
		_pausing = true
		_pause_timer = LOOK_AROUND_TIME
		# TODO: play look-around animation here


func handle_event(event: StringName, data: Dictionary = { }) -> void:
	match event:
		&"player_spotted":
			transition_requested.emit(&"chase", data)
		&"suspicious":
			transition_requested.emit(&"investigate", data)
