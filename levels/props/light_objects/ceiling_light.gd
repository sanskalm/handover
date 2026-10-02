extends AreaLight3D

@export var base_energy: float = 1.0
@export var flicker: bool = false
@export_range(0.1, 3.0, 0.1, "suffix:x") var flicker_speed: float = 1.0

@export_group("Bulb Settings")
@export_range(0.0, 1.0) var bulb_intensity_range: float = 0.3
@export_range(0.0, 1.0) var bulb_flicker_chance: float = 0.1
@export_range(0.01, 3.0, 0.01, "suffix:s") var bulb_check_interval: float = 0.1
@export_range(0.0, 20.0) var bulb_smooth_speed: float = 10.0
@export var bulb_snap: bool = true

@onready var light_object: MeshInstance3D = $LightObject

var timer: float = 0.0
var target_energy: float = 1.0
var current_energy: float = 1.0


func _ready():
	current_energy = base_energy
	target_energy = base_energy
	light_energy = base_energy


func _process(delta: float) -> void:
	if flicker:
		_flicker_process(delta)


func _flicker_process(delta: float) -> void:
	timer += delta

	if timer >= bulb_check_interval:
		timer = 0.0

		if randf() < bulb_flicker_chance:
			var flicker_amount = randf_range(0.0, bulb_intensity_range)
			target_energy = base_energy - (base_energy * flicker_amount)
		else:
			target_energy = base_energy

	else:
		return

	if bulb_snap:
		current_energy = target_energy
	else:
		current_energy = lerp(current_energy, target_energy, delta * bulb_smooth_speed)

	var mat = light_object.get_surface_override_material(0) as StandardMaterial3D

	if not mat:
		mat = light_object.get_active_material(0) as StandardMaterial3D

	var energy_ratio: float = current_energy / base_energy if base_energy > 0.0 else 0.0
	if mat:
		mat.emission_energy_multiplier = energy_ratio
		# if energy_ratio < 0.9:
		# 	mat.emission_energy_multiplier = 0.3
		# elif energy_ratio < 0.6:
		# 	mat.emission_energy_multiplier = 0.0
		# else:
		# 	mat.emission_energy_multiplier = energy_ratio * 1.0

	light_energy = current_energy
