# core/scene_manager.gd — AUTOLOAD
extends Node

@export var initial_level: PackedScene = preload("res://levels/floor_01/floor_01.tscn")

var current_level: Node3D = null
var level_holder: Node3D = null # assigned by Main, not owned by this autoload
var player: Player = null
var entity: Entity = null


func register_scene_refs(p_level_holder: Node3D, p_player: Player, p_entity: Entity) -> void:
	level_holder = p_level_holder
	player = p_player
	entity = p_entity
	change_level(initial_level, &"first")


func change_level(level_scene: PackedScene, spawn_marker_name: StringName) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	var new_level := level_scene.instantiate()
	level_holder.add_child(new_level)
	current_level = new_level

	if spawn_marker_name != &"" and new_level.has_method("get_player_spawn_marker"):
		var marker: Marker3D = new_level.get_player_spawn_marker("first")
		if marker:
			player.global_position = marker.global_position
			player.rotation = marker.rotation

	if new_level.has_method("get_patrol_checkpoints"):
		entity.set_checkpoints(new_level.get_patrol_checkpoints())
	if new_level.has_method("get_entity_spawn_marker"):
		var e_marker: Marker3D = new_level.get_entity_spawn_marker()
		if e_marker:
			entity.global_position = e_marker.global_position

	entity.set_player_ref(player)
	entity.activate()
