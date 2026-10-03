class_name EntityStatePatrol
extends State

@export var min_wait: float = 1.5
@export var max_wait: float = 6.0

var last_visited: Marker3D = null
var wait_timer: float = 0.0
var waiting: bool = false


func enter(_data: Dictionary = { }) -> void:
	waiting = false
	_pick_next_checkpoint()


func physics_process(delta: float) -> void:
	var e := owner_node as Entity

	if waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			_pick_next_checkpoint()
		return

	e.move_along_path(e.patrol_speed, delta)

	if e.navigation_agent.is_navigation_finished():
		waiting = true
		wait_timer = randf_range(min_wait, max_wait)


func _pick_next_checkpoint() -> void:
	var e := owner_node as Entity
	waiting = false

	if e.patrol_checkpoints.is_empty():
		push_warning("Patrol: no checkpoints assigned.")
		return

	var candidates := e.patrol_checkpoints.filter(
		func(c):
			return c != last_visited,
	)
	if candidates.is_empty():
		candidates = e.checkpoints

	var next: Marker3D = candidates.pick_random()
	last_visited = next
	e.go_to(next.global_position)


func handle_event(event: StringName, data: Dictionary = { }) -> void:
	match event:
		&"player_spotted":
			transition_requested.emit(&"chase", data)
		&"suspicious":
			transition_requested.emit(&"investigate", data)
		&"curious":
			transition_requested.emit(&"curious", data)
