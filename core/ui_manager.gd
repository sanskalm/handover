extends CanvasLayer

@onready var notify_label: Label = $Control/Label


func notify(text: String):
	var timer := Timer.new()
	timer.wait_time = 2.0
	notify_label.text = text
	notify_label.visible = true
	timer.timeout.connect(_clear_notify)
	add_child(timer)
	timer.start()


func _clear_notify():
	notify_label.text = ""
	notify_label.visible = false
