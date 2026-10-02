class_name Inventory
extends Node

var key_items: Dictionary = { }
var consumables: Dictionary = { }


func add_key_item(item: ItemData) -> void:
	key_items[item.id] = item


func has_key_item(id: String) -> bool:
	return key_items.has(id)


func add_consumable(item: ItemData, amount: int = 1):
	consumables[item.id] = consumables.get(item.id, 0) + amount


func has_consumable(id: String) -> bool:
	return consumables.has(id)


func remove_consumable(id: String, amount: int) -> void:
	if not consumables.has(id):
		return

	consumables[id] -= amount

	if consumables.get(id) <= 0:
		consumables.erase(id)
