extends Node

var is_invisible: bool = false
var god_mode: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_F1:
				is_invisible = !is_invisible
				print("[DEBUG] Invisibility: ", "ON" if is_invisible else "OFF")
