extends Node
class_name State

signal transition_requested(state_name: StringName, data: Dictionary)

var owner_node: Node


func enter(_data: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func process(_delta):
	pass


func physics_process(_delta: float) -> void:
	pass


func handle_event(_event: StringName, _data: Dictionary = { }) -> void:
	pass
