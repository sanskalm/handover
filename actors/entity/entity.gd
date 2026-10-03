extends CharacterBody3D
class_name Entity

@export var navigation_agent: NavigationAgent3D
@onready var state_machine: StateMachine = $StateMachine
@onready var vision: EntityVision = $Senses/Vision
@onready var perception: EntityPerception = $Senses/Perception
@onready var hearing: EntityHearing = $Senses/Hearing
@onready var footsteps_audio: AudioStreamPlayer3D = $FootstepsAudio

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var patrol_index: int = -1
@export var patrol_speed: float = 2.0
var patrol_checkpoints: Array[Marker3D]

@export var investigate_speed: float = 3.0
@export var chase_speed: float = 4.0
@export var search_speed: float = 1.0

var player: CharacterBody3D = null
var can_see_player: bool = false
var base_vision_range: float = 20

var distance_now: float = 0.0
var footstep_distance_threshold: float = 1.5

var chase_trigger_duration: float = 1
var chase_timer: float = 0.0


func _ready() -> void:
	vision.entity = self
	perception.entity = self
	hearing.entity = self

	perception.confidence_crossed_chase.connect(_on_confidence_chase)
	perception.suspicion_crossed_investigate.connect(_on_suspicion_investigate)

	perception.suspicion_stage_changed.connect(_on_stage_changed)
	perception.confidence_stage_changed.connect(_on_stage_changed)


func _on_confidence_chase(pos: Vector3) -> void:
	state_machine.handle_event(&"player_spotted", { "pos": pos })


func _on_suspicion_investigate(pos: Vector3) -> void:
	state_machine.handle_event(&"suspicious", { "pos": pos })


func _on_confidence_lost(pos: Vector3) -> void:
	state_machine.handle_event(&"player_lost", { "pos": pos })


func _on_stage_changed(_stage) -> void:
	if perception.is_chasing():
		return

	var sus := perception.get_suspicion_stage()
	var conf := perception.get_confidence_stage()

	if sus == EntityPerception.SusStage.CALM and conf == EntityPerception.ConfStage.NONE:
		state_machine.handle_event(&"calmed", { })
	else:
		state_machine.handle_event(
			&"curious",
			{ "pos": perception.get_interest_pos(), "sus_stage": sus, "conf_stage": conf },
		)


func set_player_ref(p: Player):
	player = p


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)
	_handle_gravity(delta)
	_handle_footsteps_noise(delta)


func _handle_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta
	pass


func _handle_footsteps_noise(delta: float) -> void:
	var velocity_xy := Vector2(velocity.x, velocity.z)
	if velocity_xy.length() == 0:
		distance_now = 0
		return

	distance_now += velocity_xy.length() * delta
	if distance_now >= footstep_distance_threshold:
		distance_now = 0.0
		footsteps_audio.play()


func activate():
	state_machine.start()


func set_checkpoints(new_checkpoints: Array[Marker3D]) -> void:
	patrol_checkpoints = new_checkpoints


func go_to(pos: Vector3) -> void:
	navigation_agent.target_position = pos


func move_along_path(speed: float, delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	else:
		var dir := (navigation_agent.get_next_path_position() - global_position).normalized()
		velocity = dir * speed
		if Vector2(dir.x, dir.z).length() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
	move_and_slide()
