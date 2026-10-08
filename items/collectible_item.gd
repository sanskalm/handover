class_name CollectibleItem
extends BaseItem


func _on_interacted_with(p: Player):
	p.add_to_inventory(self)
	queue_free()
