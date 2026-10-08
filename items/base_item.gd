class_name BaseItem
extends Node3D

@onready var interactable := $Interactable

@export var item_data: ItemData


func _ready() -> void:
	interactable.interacted_with.connect(_on_interacted_with)


func _on_interacted_with(p: Player):
	pass


func _process(_delta: float) -> void:
	pass
