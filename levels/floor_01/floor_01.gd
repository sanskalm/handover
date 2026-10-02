extends Node3D

@export var player_spawn_marker: Dictionary[StringName, Marker3D]
@onready var entity_spawn_marker: Marker3D = $EntitySpawn

var patrol_checkpoints: Array[Marker3D]


func _ready() -> void:
	_load_all_checkpoints()


func _load_all_checkpoints():
	for marker in get_node("Checkpoints").get_children():
		if marker is Marker3D:
			patrol_checkpoints.append(marker)


func get_patrol_checkpoints() -> Array[Marker3D]:
	return patrol_checkpoints


func get_player_spawn_marker(id: StringName) -> Marker3D:
	return player_spawn_marker.get(id)


func get_entity_spawn_marker() -> Marker3D:
	return entity_spawn_marker
