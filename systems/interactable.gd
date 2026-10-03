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
			var picked_up: bool = player.try_pickup_throwing_item(get_parent())
			if picked_up:
				process_mode = Node.PROCESS_MODE_DISABLED
				var item = get_parent() as ThrowableItem
				item.freeze_physics()

	interacted_with.emit(player)
