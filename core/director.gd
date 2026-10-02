extends Node

var player: CharacterBody3D


func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		print(player)
