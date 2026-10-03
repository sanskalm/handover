class_name EntityStateCurious
extends State
## The guard has noticed something but hasn't committed yet.
## Behavior scales with the perception stages:
##   Suspicion NOTICED            -> stop, glance toward the source
##   Suspicion ALERT              -> face it, creep forward slowly
##   Confidence DOUBT             -> stop and stare toward the player
##   Confidence BELIEVE           -> walk toward the player (add a bark here)
## When both meters drop back to calm, wait a beat ("false alarm") and return to patrol.

@export var turn_speed: float = 4.0
@export var creep_speed: float = 1.0
@export var approach_speed: float = 2.0
@export var min_approach_dist: float = 3.0 # don't walk into the player before committing
@export var calm_pause: float = 1.2 # shrug-off delay before going back to patrol

var target_pos: Vector3
var sus_stage: int = EntityPerception.SusStage.NOTICED
var conf_stage: int = EntityPerception.ConfStage.NONE
var _calm_timer: float = -1.0 # < 0 means "not calming down"


func enter(data: Dictionary = { }) -> void:
	var e := owner_node as Entity
	e.velocity = Vector3.ZERO
	_calm_timer = -1.0
	_apply(data)


func physics_process(delta: float) -> void:
	var e := owner_node as Entity

	_face(e, target_pos, delta)

	var speed := _get_move_speed()
	var dist := Vector2(e.global_position.x, e.global_position.z).distance_to(
		Vector2(target_pos.x, target_pos.z),
	)

	if speed > 0.0 and dist > min_approach_dist:
		e.go_to(target_pos)
		e.move_along_path(speed, delta)
	else:
		e.velocity = Vector3.ZERO # standing still (also stops footstep sounds)

	# False alarm: meters are calm, shrug for a moment, then resume patrol.
	if _calm_timer >= 0.0:
		_calm_timer -= delta
		if _calm_timer <= 0.0:
			transition_requested.emit(&"patrol", { })


func handle_event(event: StringName, data: Dictionary = { }) -> void:
	match event:
		&"curious":
			_calm_timer = -1.0 # something new happened, cancel the shrug
			_apply(data)
		&"calmed":
			_calm_timer = calm_pause
		&"suspicious":
			transition_requested.emit(&"investigate", data)
		&"player_spotted":
			transition_requested.emit(&"chase", data)


func _apply(data: Dictionary) -> void:
	var e := owner_node as Entity
	target_pos = data.get("pos", target_pos if target_pos != Vector3.ZERO else e.global_position)
	sus_stage = data.get("sus_stage", sus_stage)
	conf_stage = data.get("conf_stage", conf_stage)


func _get_move_speed() -> float:
	# Confidence outranks suspicion: "I think that's the player" beats "I heard something".
	if conf_stage == EntityPerception.ConfStage.BELIEVE:
		return approach_speed
	if conf_stage == EntityPerception.ConfStage.DOUBT:
		return 0.0 # stare
	if sus_stage == EntityPerception.SusStage.ALERT:
		return creep_speed
	return 0.0 # NOTICED: just glance


func _face(e: Entity, pos: Vector3, delta: float) -> void:
	var dir := pos - e.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	e.rotation.y = lerp_angle(e.rotation.y, atan2(-dir.x, -dir.z), turn_speed * delta)
