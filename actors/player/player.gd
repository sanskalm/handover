extends CharacterBody3D
class_name Player

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.5

# Temporary
@export var throwable_scene: PackedScene
#

@export var crouch_speed: float = 1.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var footsteps_audio: AudioStreamPlayer3D = $Audio/Footsteps
@onready var flashlight: SpotLight3D = $Head/LeftHand/Flashlight/Flashlight
@onready var uv_light: SpotLight3D = $Head/LeftHand/UVLight/UVLight
@onready var interact_raycast: RayCast3D = $Head/InteractRaycast
@onready var inventory: Inventory = $Inventory
@onready var right_hand: Node3D = $Head/RightHand

var is_moving: bool = false
var is_crouching: bool = false

var footstep_distance_threshold: float = 1.5
var min_movement_speed: float = 0.5
var distance_now: float = 0.0
var current_speed: float = SPEED

var stand_head_position: Vector3
var crouch_head_position: Vector3

var head_tween: Tween

var current_light: Light3D


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stand_head_position = head.position
	crouch_head_position = Vector3(head.position.x, 0.2, head.position.z)
	flashlight.visible = false
	uv_light.visible = false
	current_light = flashlight
	current_light.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_light"):
		current_light.visible = !flashlight.visible
	if event.is_action_pressed("switch_light"):
		_switch_light()
	if Input.is_action_just_pressed("interact"):
		_try_interact_raycast()
	if Input.is_action_just_pressed("throw"):
		_try_throwing_item()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return
	var yaw = event.relative.x * MOUSE_SENSITIVITY
	var pitch = event.relative.y * MOUSE_SENSITIVITY
	rotate_y(deg_to_rad(-yaw))
	head.rotate_x(deg_to_rad(-pitch))
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_footsteps_noise(delta)


func _switch_light() -> void:
	if current_light == flashlight:
		current_light = uv_light
	else:
		current_light = flashlight

	flashlight.visible = false
	uv_light.visible = false
	current_light.visible = true


func try_pickup_throwing_item(item: ThrowableItem) -> bool:
	if not right_hand.get_children().is_empty():
		return false

	item.reparent(right_hand, false)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	return true


func _try_throwing_item():
	for c in right_hand.get_children():
		if c is ThrowableItem:
			var forward_dir: Vector3 = -camera.global_transform.basis.z
			var throw_dir: Vector3 = (forward_dir + Vector3.UP * 0.2).normalized()

			c.reparent(get_tree().get_first_node_in_group("level"), true)
			c.throw(throw_dir)
			break


func _try_interact_raycast():
	if not interact_raycast.is_colliding():
		return
	var collider = interact_raycast.get_collider()
	if collider is not Interactable:
		return
	collider.interact(self)


func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	_handle_crouch(delta)

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * (SPEED if not is_crouching else crouch_speed)
		velocity.z = direction.z * (SPEED if not is_crouching else crouch_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if velocity.length() > 0:
		is_moving = true
	else:
		is_moving = false

	move_and_slide()


func _handle_crouch(_delta):
	if Input.is_action_just_pressed("crouch"):
		is_crouching = !is_crouching

		var target_pos = crouch_head_position if is_crouching else stand_head_position

		if head_tween and head_tween.is_running():
			head_tween.kill()

		head_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		head_tween.tween_property(head, "position", target_pos, 0.2)


func _handle_footsteps_noise(delta: float) -> void:
	var velocity_xy := Vector2(velocity.x, velocity.z)
	if velocity_xy.length() <= Vector3(crouch_speed, 0, crouch_speed).length():
		distance_now = 0
		return

	distance_now += velocity_xy.length() * delta
	if distance_now >= footstep_distance_threshold:
		distance_now = 0.0
		Events.noise_emitted.emit(NoiseEvent.new(global_position, 20.0, NoiseEvent.Type.FOOTSTEP))
		footsteps_audio.play()


func _add_to_inventory(item: Item):
	pass
