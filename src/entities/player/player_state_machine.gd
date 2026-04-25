extends Node

## 플레이어 행동 상태를 관리하고 전이를 결정한다.
## Phase 4-0 #4: 강화 이동 3종(SHADOW_STEP/LIGHT_LEAP/SHADOW_PHASE) + 속성 토글.
## current_dash_attribute(NEUTRAL/LIGHT/SHADOW) × 지상/공중 분기로 dash 키가 다르게 동작한다.
## light_dash 직접 키(O)는 보스 보상 즉시 체감용 레거시로 유지.

signal state_changed(old_state: State, new_state: State)
signal dash_attribute_changed(attribute: DashAttribute)

enum State { IDLE, RUN, JUMP, FALL, DASH, LIGHT_DASH, SHADOW_STEP, LIGHT_LEAP, SHADOW_PHASE }

enum DashAttribute { NEUTRAL, LIGHT, SHADOW }

const ABILITY_LIGHT_DASH := "light_dash"
const ABILITY_SHADOW_STEP := "shadow_step"
const ABILITY_LIGHT_LEAP := "light_leap"
const ABILITY_SHADOW_PHASE := "shadow_phase"

var current_state: State = State.IDLE
var current_dash_attribute: DashAttribute = DashAttribute.NEUTRAL
var air_jump_count: int = 0
var can_dash: bool = true
var can_light_dash: bool = true
var can_shadow_step: bool = true
var can_light_leap: bool = true
var can_shadow_phase: bool = true
var coyote_active: bool = false
var dash_active: bool = false
var light_dash_active: bool = false
var shadow_step_active: bool = false
var light_leap_active: bool = false
var shadow_phase_active: bool = false

var _coyote_timer: Timer
var _dash_duration_timer: Timer
var _dash_cooldown_timer: Timer
var _light_dash_duration_timer: Timer
var _light_dash_cooldown_timer: Timer
var _shadow_step_duration_timer: Timer
var _shadow_step_cooldown_timer: Timer
var _light_leap_duration_timer: Timer
var _light_leap_cooldown_timer: Timer
var _shadow_phase_duration_timer: Timer
var _shadow_phase_cooldown_timer: Timer
var _max_air_jumps: int = 1
var _stats: PlayerStatsData


func setup(
	coyote_timer: Timer,
	dash_duration_timer: Timer,
	dash_cooldown_timer: Timer,
	light_dash_duration_timer: Timer,
	light_dash_cooldown_timer: Timer,
	max_air_jumps: int,
	stats: PlayerStatsData
) -> void:
	_coyote_timer = coyote_timer
	_dash_duration_timer = dash_duration_timer
	_dash_cooldown_timer = dash_cooldown_timer
	_light_dash_duration_timer = light_dash_duration_timer
	_light_dash_cooldown_timer = light_dash_cooldown_timer
	_max_air_jumps = max_air_jumps
	_stats = stats

	_coyote_timer.timeout.connect(_on_coyote_timeout)
	_dash_duration_timer.timeout.connect(_on_dash_duration_timeout)
	_dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	_light_dash_duration_timer.timeout.connect(_on_light_dash_duration_timeout)
	_light_dash_cooldown_timer.timeout.connect(_on_light_dash_cooldown_timeout)

	_create_enhanced_movement_timers()


## Phase 4-0 #4 신규 6 Timer를 코드로 동적 생성 — Player.tscn 변경 없이 확장.
func _create_enhanced_movement_timers() -> void:
	_shadow_step_duration_timer = _make_timer("ShadowStepDuration", _stats.shadow_step_iframe)
	_shadow_step_duration_timer.timeout.connect(_on_shadow_step_duration_timeout)
	_shadow_step_cooldown_timer = _make_timer("ShadowStepCooldown", _stats.shadow_step_cooldown)
	_shadow_step_cooldown_timer.timeout.connect(_on_shadow_step_cooldown_timeout)
	_light_leap_duration_timer = _make_timer("LightLeapDuration", _stats.light_leap_duration)
	_light_leap_duration_timer.timeout.connect(_on_light_leap_duration_timeout)
	_light_leap_cooldown_timer = _make_timer("LightLeapCooldown", _stats.light_leap_cooldown)
	_light_leap_cooldown_timer.timeout.connect(_on_light_leap_cooldown_timeout)
	_shadow_phase_duration_timer = _make_timer("ShadowPhaseDuration", _stats.shadow_phase_duration)
	_shadow_phase_duration_timer.timeout.connect(_on_shadow_phase_duration_timeout)
	_shadow_phase_cooldown_timer = _make_timer("ShadowPhaseCooldown", _stats.shadow_phase_cooldown)
	_shadow_phase_cooldown_timer.timeout.connect(_on_shadow_phase_cooldown_timeout)


func _make_timer(timer_name: String, wait_time: float) -> Timer:
	var t := Timer.new()
	t.name = timer_name
	t.one_shot = true
	t.wait_time = wait_time
	add_child(t)
	return t


func update(input: Node, is_on_floor: bool, velocity: Vector2) -> void:
	var new_state := current_state

	match current_state:
		State.IDLE:
			new_state = _update_idle(input, is_on_floor)
		State.RUN:
			new_state = _update_run(input, is_on_floor)
		State.JUMP:
			new_state = _update_jump(input, velocity)
		State.FALL:
			new_state = _update_fall(input, is_on_floor)
		State.DASH:
			new_state = _update_active_state(is_on_floor, dash_active, State.DASH)
		State.LIGHT_DASH:
			new_state = _update_active_state(is_on_floor, light_dash_active, State.LIGHT_DASH)
		State.SHADOW_STEP:
			new_state = _update_active_state(is_on_floor, shadow_step_active, State.SHADOW_STEP)
		State.LIGHT_LEAP:
			new_state = _update_active_state(is_on_floor, light_leap_active, State.LIGHT_LEAP)
		State.SHADOW_PHASE:
			new_state = _update_active_state(is_on_floor, shadow_phase_active, State.SHADOW_PHASE)

	if new_state != current_state:
		_transition(new_state, is_on_floor)


## V 키 입력 → player.gd가 호출. NEUTRAL → LIGHT → SHADOW → NEUTRAL 순환.
func toggle_attribute() -> void:
	current_dash_attribute = ((current_dash_attribute + 1) % 3) as DashAttribute
	dash_attribute_changed.emit(current_dash_attribute)
	# 임시 디버그 — Step 6에서 HUD 아이콘으로 대체.
	print("[Player] dash attribute → %s" % _attribute_label(current_dash_attribute))


func _attribute_label(attr: DashAttribute) -> String:
	match attr:
		DashAttribute.LIGHT:
			return "LIGHT"
		DashAttribute.SHADOW:
			return "SHADOW"
		_:
			return "NEUTRAL"


func _update_idle(input: Node, is_on_floor: bool) -> State:
	var dash_state: State = _check_dash_inputs(input, is_on_floor)
	if dash_state != current_state:
		return dash_state
	if input.jump_pressed and is_on_floor:
		return State.JUMP
	if not is_on_floor:
		_start_coyote()
		return State.FALL
	if input.move_direction != 0.0:
		return State.RUN
	return State.IDLE


func _update_run(input: Node, is_on_floor: bool) -> State:
	var dash_state: State = _check_dash_inputs(input, is_on_floor)
	if dash_state != current_state:
		return dash_state
	if input.jump_pressed and is_on_floor:
		return State.JUMP
	if not is_on_floor:
		_start_coyote()
		return State.FALL
	if input.move_direction == 0.0:
		return State.IDLE
	return State.RUN


func _update_jump(input: Node, velocity: Vector2) -> State:
	var dash_state: State = _check_dash_inputs(input, false)
	if dash_state != current_state:
		return dash_state
	if input.jump_pressed and air_jump_count < _get_max_air_jumps():
		air_jump_count += 1
		return State.JUMP  # 2단 점프: 재진입
	if velocity.y >= 0.0:
		return State.FALL
	return State.JUMP


func _update_fall(input: Node, is_on_floor: bool) -> State:
	var dash_state: State = _check_dash_inputs(input, is_on_floor)
	if dash_state != current_state:
		return dash_state
	if is_on_floor:
		if input.move_direction != 0.0:
			return State.RUN

		return State.IDLE
	if input.jump_pressed:
		if coyote_active:
			coyote_active = false
			_coyote_timer.stop()
			return State.JUMP
		if air_jump_count < _get_max_air_jumps():
			air_jump_count += 1
			return State.JUMP
	return State.FALL


## DASH/LIGHT_DASH/SHADOW_STEP/LIGHT_LEAP/SHADOW_PHASE 종료 시 IDLE/FALL 복귀.
func _update_active_state(is_on_floor: bool, still_active: bool, fallback: State) -> State:
	if not still_active:
		if is_on_floor:
			return State.IDLE
		return State.FALL
	return fallback


## Phase 4-0 #4: dash 키가 (속성 × 지상/공중) × 해금 여부로 분기.
## - LIGHT/지상: LIGHT_DASH (해금 시) — 기존 light_dash 능력 재사용
## - LIGHT/공중: LIGHT_LEAP (해금 시)
## - SHADOW/지상: SHADOW_STEP (해금 시)
## - SHADOW/공중: SHADOW_PHASE (해금 시)
## - NEUTRAL 또는 미해금: 기본 DASH (폴백)
## light_dash 키(O)는 LIGHT_DASH 직접 호출 레거시 유지 — 보스 보상 즉시 체감용.
func _check_dash_inputs(input: Node, is_on_floor: bool) -> State:
	if input.light_dash_pressed and can_light_dash and _has_ability(ABILITY_LIGHT_DASH):
		return State.LIGHT_DASH
	if not input.dash_pressed:
		return current_state
	var resolved: State = _resolve_attribute_dash(is_on_floor)
	if resolved != current_state:
		return resolved
	# NEUTRAL 또는 해금 안 됨 → 기본 dash 폴백
	if can_dash:
		return State.DASH
	return current_state


func _resolve_attribute_dash(is_on_floor: bool) -> State:
	match current_dash_attribute:
		DashAttribute.LIGHT:
			if is_on_floor:
				if can_light_dash and _has_ability(ABILITY_LIGHT_DASH):
					return State.LIGHT_DASH
			elif can_light_leap and _has_ability(ABILITY_LIGHT_LEAP):
				return State.LIGHT_LEAP
		DashAttribute.SHADOW:
			if is_on_floor:
				if can_shadow_step and _has_ability(ABILITY_SHADOW_STEP):
					return State.SHADOW_STEP
			elif can_shadow_phase and _has_ability(ABILITY_SHADOW_PHASE):
				return State.SHADOW_PHASE
	return current_state


func _has_ability(ability_id: String) -> bool:
	if has_node("/root/AbilitySystem"):
		return get_node("/root/AbilitySystem").has(ability_id)
	return false


func _transition(new_state: State, is_on_floor: bool) -> void:
	var old_state := current_state
	current_state = new_state

	# 착지 시 리셋
	var aerial: Array = [
		State.JUMP,
		State.FALL,
		State.DASH,
		State.LIGHT_DASH,
		State.SHADOW_STEP,
		State.LIGHT_LEAP,
		State.SHADOW_PHASE,
	]
	if is_on_floor and old_state in aerial:
		air_jump_count = 0
		can_dash = true

	# 상태 진입 처리
	match new_state:
		State.DASH:
			dash_active = true
			can_dash = false
			_dash_duration_timer.start()
			_dash_cooldown_timer.start()
		State.LIGHT_DASH:
			light_dash_active = true
			can_light_dash = false
			_light_dash_duration_timer.start()
			_light_dash_cooldown_timer.start()
		State.SHADOW_STEP:
			shadow_step_active = true
			can_shadow_step = false
			_shadow_step_duration_timer.start()
			_shadow_step_cooldown_timer.start()
		State.LIGHT_LEAP:
			light_leap_active = true
			can_light_leap = false
			_light_leap_duration_timer.start()
			_light_leap_cooldown_timer.start()
		State.SHADOW_PHASE:
			shadow_phase_active = true
			can_shadow_phase = false
			_shadow_phase_duration_timer.start()
			_shadow_phase_cooldown_timer.start()

	state_changed.emit(old_state, new_state)


func _start_coyote() -> void:
	coyote_active = true
	_coyote_timer.start()


func _on_coyote_timeout() -> void:
	coyote_active = false


func _on_dash_duration_timeout() -> void:
	dash_active = false


func _on_dash_cooldown_timeout() -> void:
	can_dash = true


func _on_light_dash_duration_timeout() -> void:
	light_dash_active = false


func _on_light_dash_cooldown_timeout() -> void:
	can_light_dash = true


func _on_shadow_step_duration_timeout() -> void:
	shadow_step_active = false


func _on_shadow_step_cooldown_timeout() -> void:
	can_shadow_step = true


func _on_light_leap_duration_timeout() -> void:
	light_leap_active = false


func _on_light_leap_cooldown_timeout() -> void:
	can_light_leap = true


func _on_shadow_phase_duration_timeout() -> void:
	shadow_phase_active = false


func _on_shadow_phase_cooldown_timeout() -> void:
	can_shadow_phase = true


## 외부(4타 피니시 light 속성)가 능력 해금·쿨다운 무관하게 LIGHT_DASH 상태로 강제 전이.
## 이동·i-frame·afterimage는 기존 LIGHT_DASH 경로(player_movement + player_light_dash) 재사용.
func force_light_dash() -> void:
	var is_on_floor: bool = true  # 피니시 상태 종료 시 착지 처리는 다음 update에서 자연 해소.
	_transition(State.LIGHT_DASH, is_on_floor)


func _get_max_air_jumps() -> int:
	return _max_air_jumps
