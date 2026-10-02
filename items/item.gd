class_name Item
extends Node3D

@export var item_name: String = "Item"
@export var item_id: StringName
@export var item_type: ItemData.ItemType
@export var icon: Texture2D
@export var description: String

@onready var interactable := $Interactable

var item_data: ItemData


func _ready() -> void:
	interactable.interacted_with.connect(_on_interacted_with)
	item_data = ItemData.new(item_id, item_name, item_type, description, icon)


func _on_interacted_with(p: Player):
	pass


func _process(_delta: float) -> void:
	pass
