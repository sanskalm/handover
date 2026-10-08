class_name ItemData
extends Resource

enum UseType {
	NONE,
	INSPECT,
	CONSUME,
}

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var use_type: UseType = UseType.NONE
@export_multiline var text: String
@export var inspect_on_pickup: bool = false
@export var heal_amount: int = 0
