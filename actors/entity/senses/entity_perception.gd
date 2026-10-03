class_name EntityPerception
extends Node
## Suspicion  = "something's off"       (noise + vision, fades slowly)
## Confidence = "I know what I saw"     (vision only, boosted by suspicion, fades fast)
## Alertness  = long-term paranoia      (rises after each investigate/chase, fades very slowly)
##
## Each meter has STAGES that the AI can react to long before the guard commits:
##   Suspicion : CALM -> NOTICED -> ALERT -> (commit) investigate
##   Confidence: NONE -> DOUBT   -> BELIEVE -> (commit) chase

enum SusStage {
	CALM,
	NOTICED,
	ALERT,
}
enum ConfStage {
	NONE,
	DOUBT,
	BELIEVE,
}

# Stage changes (use these to drive "look", "turn", "approach" behaviors)
signal suspicion_stage_changed(stage: SusStage)
signal confidence_stage_changed(stage: ConfStage)
# Commits
signal suspicion_crossed_investigate(pos: Vector3)
signal confidence_crossed_chase(pos: Vector3)
signal confidence_lost(pos: Vector3)

# ---------- STAGES ----------
@export_group("Stages")
@export var sus_noticed_at: float = 25.0 # stop + glance toward source
@export var sus_alert_at: float = 60.0 # turn toward it, slow approach
@export var conf_doubt_at: float = 40.0 # "was that someone?" stare
@export var conf_believe_at: float = 80.0 # "that's the player" move toward + warn

# ---------- COMMIT THRESHOLDS ----------
@export_group("Commit")
@export var investigate_threshold: float = 100.0
@export var chase_threshold: float = 100.0
@export var chase_release: float = 25.0 # confidence below this ends a chase
@export var jumpy_window: float = 15.0 # saw you recently -> easier to chase
@export var jumpy_bonus: float = 10.0
@export var investigate_residual: float = 40.0 # suspicion left after investigating
@export var investigate_cooldown: float = 3.0
## Double take: meter must stay at threshold this long before committing.
@export var reaction_investigate: float = 0.5
@export var reaction_chase: float = 0.35
@export var reaction_jitter: float = 0.3 # +/- per entity, so guards aren't clones

# ---------- GAINS ----------
@export_group("Gains")
# Vision: PER SECOND at strength 1.0 (scaled by the sample interval).
@export var sus_vision_rate: float = 45.0
@export var sus_vision_rate_unclear: float = 12.0
@export var conf_vision_rate: float = 50.0
@export var conf_vision_rate_unclear: float = 8.0
# Noise: PER EVENT (footstep, thrown object...).
@export var sus_noise_gain: float = 50.0

# ---------- DECAY ----------
@export_group("Decay")
@export var sus_grace: float = 3.0
@export var conf_grace: float = 1.0
@export var sus_decay_rate: float = 6.0
@export var conf_decay_rate: float = 15.0

# ---------- ALERTNESS ----------
const ALERT_ON_INVESTIGATE: float = 0.15
const ALERT_ON_CHASE: float = 0.30
const ALERT_DECAY: float = 0.01 # per second (~100s to fully relax)
const ALERT_THRESHOLD_DROP: float = 15.0 # commit thresholds drop by up to this
const ALERT_SUS_BOOST: float = 0.5 # suspicion gains up to +50%

var entity: Entity = null

var suspicion: float = 0.0
var confidence: float = 0.0
var alertness: float = 0.0

var last_seen_pos: Vector3
var last_seen_time: float = -999.0
var last_noise_pos: Vector3
var last_noise_time: float = -999.0

var _last_sus_stim: float = -999.0
var _last_conf_stim: float = -999.0
var _chasing: bool = false
var _chase_hold: float = 0.0
var _inv_hold: float = 0.0
var _investigate_ready_at: float = 0.0
var _react_inv: float
var _react_chase: float
var _sus_stage: SusStage = SusStage.CALM
var _conf_stage: ConfStage = ConfStage.NONE


func _ready() -> void:
	_react_inv = reaction_investigate * randf_range(1.0 - reaction_jitter, 1.0 + reaction_jitter)
	_react_chase = reaction_chase * randf_range(1.0 - reaction_jitter, 1.0 + reaction_jitter)


func _process(delta: float) -> void:
	var now := _now()
	alertness = max(0.0, alertness - ALERT_DECAY * delta)
	_decay(delta, now)
	_check_commits(delta, now)
	_update_stages()

# ---------- INPUTS ----------


func on_noise(strength: float, pos: Vector3) -> void:
	if strength <= 0.0:
		return
	var now := _now()
	suspicion += strength * sus_noise_gain * _sus_multiplier()
	last_noise_pos = pos
	last_noise_time = now
	_last_sus_stim = now
	_clamp_meters()


## `delta` = time since the last on_vision sample (EntityVision's check_interval).
func on_vision(strength: float, is_clear: bool, pos: Vector3, delta: float = 0.1) -> void:
	if strength <= 0.0:
		return
	var now := _now()

	if is_clear:
		suspicion += strength * sus_vision_rate * _sus_multiplier() * delta
		# Hard to be sure of something you had no reason to suspect.
		var belief := lerpf(0.3, 1.0, suspicion / 100.0)
		confidence += strength * conf_vision_rate * belief * delta
		_last_conf_stim = now
	else:
		suspicion += strength * sus_vision_rate_unclear * _sus_multiplier() * delta
		confidence += strength * conf_vision_rate_unclear * delta
		if _chasing:
			_last_conf_stim = now # any sighting keeps an active chase going

	last_seen_pos = pos
	last_seen_time = now
	_last_sus_stim = now
	_clamp_meters()


func force_spot(pos: Vector3) -> void:
	last_seen_pos = pos
	last_seen_time = _now()
	confidence = 100.0
	suspicion = 100.0
	_last_sus_stim = last_seen_time
	_last_conf_stim = last_seen_time
	if not _chasing: # called repeatedly at close range, so only emit once
		_start_chase()
	_update_stages()

# ---------- PUBLIC READ-ONLY (AI / debug UI) ----------


func is_chasing() -> bool:
	return _chasing


func get_suspicion_stage() -> SusStage:
	return _sus_stage


func get_confidence_stage() -> ConfStage:
	return _conf_stage


func get_chase_threshold() -> float:
	return _get_chase_threshold(_now())


func get_investigate_threshold() -> float:
	return _get_investigate_threshold()


## Where the guard should look right now: latest noise or sighting.
func get_interest_pos() -> Vector3:
	return last_noise_pos if last_noise_time > last_seen_time else last_seen_pos

# ---------- INTERNALS ----------


func _decay(delta: float, now: float) -> void:
	var relax := 1.0 - 0.5 * alertness # paranoid guards calm down slower
	if now - _last_sus_stim > sus_grace:
		suspicion = max(0.0, suspicion - sus_decay_rate * relax * delta)
	if now - _last_conf_stim > conf_grace:
		confidence = max(0.0, confidence - conf_decay_rate * relax * delta)


func _check_commits(delta: float, now: float) -> void:
	# --- Chase ---
	if not _chasing:
		if confidence >= _get_chase_threshold(now):
			_chase_hold += delta
			if _chase_hold >= _react_chase:
				_start_chase()
				return
		else:
			_chase_hold = 0.0
	elif confidence < chase_release:
		_chasing = false
		confidence_lost.emit(last_seen_pos)

	# --- Investigate (not while chasing, with cooldown) ---
	if _chasing or now < _investigate_ready_at:
		return
	if suspicion >= _get_investigate_threshold():
		_inv_hold += delta
		if _inv_hold >= _react_inv:
			_inv_hold = 0.0
			suspicion = investigate_residual # stays wary instead of resetting to 0
			_investigate_ready_at = now + investigate_cooldown
			alertness = min(1.0, alertness + ALERT_ON_INVESTIGATE)
			suspicion_crossed_investigate.emit(get_interest_pos())
	else:
		_inv_hold = 0.0


func _start_chase() -> void:
	_chasing = true
	_chase_hold = 0.0
	_inv_hold = 0.0
	alertness = min(1.0, alertness + ALERT_ON_CHASE)
	confidence_crossed_chase.emit(last_seen_pos)
	# Confidence is NOT zeroed: losing the player feels like "where did they go?"


func _update_stages() -> void:
	var s: SusStage = SusStage.CALM
	if suspicion >= sus_alert_at:
		s = SusStage.ALERT
	elif suspicion >= sus_noticed_at:
		s = SusStage.NOTICED
	if s != _sus_stage:
		_sus_stage = s
		suspicion_stage_changed.emit(s)

	var c: ConfStage = ConfStage.NONE
	if confidence >= conf_believe_at:
		c = ConfStage.BELIEVE
	elif confidence >= conf_doubt_at:
		c = ConfStage.DOUBT
	if c != _conf_stage:
		_conf_stage = c
		confidence_stage_changed.emit(c)


func _get_chase_threshold(now: float) -> float:
	var t := chase_threshold - ALERT_THRESHOLD_DROP * alertness
	if now - last_seen_time < jumpy_window:
		t -= jumpy_bonus
	# Never commit before the "believe" stage, so the stages always come first.
	return max(conf_believe_at, t)


func _get_investigate_threshold() -> float:
	return max(sus_alert_at, investigate_threshold - ALERT_THRESHOLD_DROP * alertness)


func _sus_multiplier() -> float:
	return 1.0 + ALERT_SUS_BOOST * alertness


func _clamp_meters() -> void:
	suspicion = clampf(suspicion, 0.0, 100.0)
	confidence = clampf(confidence, 0.0, 100.0)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
