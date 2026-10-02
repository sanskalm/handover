extends Item


func _on_interacted_with(p: Player):
	# TODO: important items should switch game flag
	p.inventory.add_key_item(item_data)
	Events.key_room_a_acquired.emit()
	UiManager.notify("Key Room A Acquired")
	queue_free()


func _process(_delta: float) -> void:
	pass
