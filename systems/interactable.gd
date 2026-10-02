class_name Interactable
extends Area3D

signal interacted_with(player: Player)

enum InteractType {
	PICKUP,
	SWITCH,
}

@export var interact_type: InteractType


func interact(player: Player):
	interacted_with.emit(player)
