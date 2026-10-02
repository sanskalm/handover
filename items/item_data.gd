class_name ItemData

var id: String
var display_name: String
var description: String
var icon: Texture2D
var type: ItemType

enum ItemType {
	KEY_ITEM,
	CONSUMABLE,
}


func _init(
	p_id: String,
	p_display_name: String,
	p_type: ItemType,
	p_description: String = "",
	p_icon: Texture2D = null,
):
	id = p_id
	display_name = p_display_name
	type = p_type
	description = p_description
	icon = p_icon
