extends Node3D


func play_spatial_sound(stream: AudioStream, position: Vector3, bus: StringName = &"SFX"):
	if not stream:
		return

	var audio_player := AudioStreamPlayer3D.new()
	audio_player.stream = stream
	audio_player.global_position = position
	audio_player.bus = bus

	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	audio_player.unit_size = 3.0
	audio_player.panning_strength = 1.0

	add_child(audio_player)
	audio_player.play()

	audio_player.finished.connect(queue_free)
