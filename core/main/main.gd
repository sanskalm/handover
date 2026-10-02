extends Node

@onready var level_holder: Node3D = $LevelHolder
@onready var player: Player = $Player
@onready var entity: Entity = $Entity


func _ready() -> void:
	SceneManager.register_scene_refs(level_holder, player, entity)
