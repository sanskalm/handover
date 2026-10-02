class_name EntityPerception
extends Node

signal confidence_crossed_chase(pos: Vector3)
signal suspicion_crossed_investigate(pos: Vector3)

const DECAY_THRESHOLD: float = 1.0
const SUSPICION_DECAY: float = 10.0
const CONFIDENCE_DECAY: float = 10.0
const INVESTIGATE_THRESHOLD: float = 50.0
const CHASE_THRESHOLD_BASE: float = 50.0
const CHASE_THRESHOLD_JUMPY: float = 60.0
const JUMPY_WINDOW: float = 15.0

@export var sus_increment: float = 70.0
@export var conf_increment: float = 30.0

var entity: Entity = null

var suspicion: float = 0.0
var confidence: float = 0.0
var last_seen_pos: Vector3
var last_seen_time: float = -999.0

var decay_timer: float


func _process(delta: float) -> void:
	decay_timer += delta
	if decay_timer >= DECAY_THRESHOLD:
		decay_timer = 0.0
		suspicion = max(0.0, suspicion - SUSPICION_DECAY)
		confidence = max(0.0, confidence - CONFIDENCE_DECAY)
		if last_seen_pos == null:
			return
		var chase_threshold := _get_dynamic_chase_threshold()

		if confidence >= chase_threshold:
			confidence_crossed_chase.emit(last_seen_pos)
			confidence = 0.0
		elif suspicion >= INVESTIGATE_THRESHOLD:
			suspicion_crossed_investigate.emit(last_seen_pos)
			suspicion = 0.0


func on_noise(strength: float, pos: Vector3) -> void:
	suspicion += strength * sus_increment
	last_seen_pos = pos
	_clamp_meters()


func force_spot(pos: Vector3) -> void:
	last_seen_pos = pos
	last_seen_time = Time.get_ticks_msec() / 1000.0
	confidence = 100.0
	confidence_crossed_chase.emit(pos)
	confidence = 0.0


func on_vision(strength: float, is_clear: bool, pos: Vector3) -> void:
	if strength <= 0.0:
		return
	if is_clear:
		suspicion += strength * sus_increment
		confidence += strength * conf_increment
	else:
		suspicion += strength * 5.0
		confidence += strength * 10.0
	last_seen_pos = pos
	last_seen_time = Time.get_ticks_msec() / 1000.0
	_clamp_meters()


func _get_dynamic_chase_threshold() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_seen_time < JUMPY_WINDOW:
		return CHASE_THRESHOLD_JUMPY
	return CHASE_THRESHOLD_BASE


func _clamp_meters() -> void:
	suspicion = clamp(suspicion, 0.0, 100.0)
	confidence = clamp(confidence, 0.0, 100.0)
