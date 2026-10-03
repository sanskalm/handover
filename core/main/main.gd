extends Node

@onready var level_holder: Node3D = $LevelHolder
@onready var player: Player = $LevelHolder/Player
@onready var entity: Entity = $LevelHolder/Entity

var paused: bool = false


func _ready() -> void:
	SceneManager.register_scene_refs(level_holder, player, entity)


func _input(event):
	if Input.is_action_just_pressed("debug_pause"):
		paused = !paused
	if paused:
		level_holder.process_mode = Node.PROCESS_MODE_DISABLED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		level_holder.process_mode = Node.PROCESS_MODE_ALWAYS
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
