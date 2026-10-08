class_name Interactable
extends Area3D

signal interacted_with(player: Player)
@export var prompt_text: String = "Interact"


func interact(player: Player):
	interacted_with.emit(player)
