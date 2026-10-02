class_name Interactable
extends Area3D

signal interacted_with(player: Player)

enum InteractType {
	PICKUP,
	SWITCH,
	THROWABLE,
}

@export var interact_type: InteractType


func interact(player: Player):
	match interact_type:
		InteractType.PICKUP:
			pass
		InteractType.SWITCH:
			pass
		InteractType.THROWABLE:
			player.try_pickup_throwing_item(get_parent())
			process_mode = Node.PROCESS_MODE_DISABLED

	interacted_with.emit(player)
