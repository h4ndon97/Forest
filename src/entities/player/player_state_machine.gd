extends Node

## 플레이어 행동 상태를 관리하고 전이를 결정한다.

enum State { IDLE, RUN, JUMP, FALL, DASH, LIGHT_DASH }

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.IDLE
var air_jump_count: int = 0
var can_dash: bool = true
var can_light_dash: bool = true
var coyote_active: bool = false
var dash_active: bool = false
var light_dash_active: bool = false

var _coyote_timer: Timer
var _dash_duration_timer: Timer
var _dash_cooldown_timer: Timer
var _light_dash_duration_timer: Timer
var _light_dash_cooldown_timer: Timer
var _max_air_jumps: int = 1


func setup(
	coyote_timer: Timer,
	dash_duration_timer: Timer,
	dash_cooldown_timer: Timer,
	light_dash_duration_timer: Timer,
	light_dash_cooldown_timer: Timer,
	max_air_jumps: int = 1
) -> void:
	_coyote_timer = coyote_timer
	_dash_duration_timer = dash_duration_timer
	_dash_cooldown_timer = dash_cooldown_timer
	_light_dash_duration_timer = light_dash_duration_timer
	_light_dash_cooldown_timer = light_dash_cooldown_timer
	_max_air_jumps = max_air_jumps

	_coyote_timer.timeout.connect(_on_coyote_timeout)
	_dash_duration_timer.timeout.connect(_on_dash_duration_timeout)
	_dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	_light_dash_duration_timer.timeout.connect(_on_light_dash_duration_timeout)
	_light_dash_cooldown_timer.timeout.connect(_on_light_dash_cooldown_timeout)


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
			new_state = _update_dash(is_on_floor)
		State.LIGHT_DASH:
			new_state = _update_light_dash(is_on_floor)

	if new_state != current_state:
		_transition(new_state, is_on_floor)


func _update_idle(input: Node, is_on_floor: bool) -> State:
	var dash_state: State = _check_dash_inputs(input)
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
	var dash_state: State = _check_dash_inputs(input)
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
	var dash_state: State = _check_dash_inputs(input)
	if dash_state != current_state:
		return dash_state
	if input.jump_pressed and air_jump_count < _get_max_air_jumps():
		air_jump_count += 1
		return State.JUMP  # 2단 점프: 재진입
	if velocity.y >= 0.0:
		return State.FALL
	return State.JUMP


func _update_fall(input: Node, is_on_floor: bool) -> State:
	var dash_state: State = _check_dash_inputs(input)
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


func _update_dash(is_on_floor: bool) -> State:
	if not dash_active:
		if is_on_floor:
			return State.IDLE
		return State.FALL
	return State.DASH


func _update_light_dash(is_on_floor: bool) -> State:
	if not light_dash_active:
		if is_on_floor:
			return State.IDLE
		return State.FALL
	return State.LIGHT_DASH


## 빛 대시(능력 보유)가 일반 대시보다 우선. 둘 다 키가 같이 눌렸을 때를 위함.
func _check_dash_inputs(input: Node) -> State:
	if input.light_dash_pressed and can_light_dash and _has_light_dash_ability():
		return State.LIGHT_DASH
	if input.dash_pressed and can_dash:
		return State.DASH
	return current_state


func _has_light_dash_ability() -> bool:
	if has_node("/root/AbilitySystem"):
		return get_node("/root/AbilitySystem").has("light_dash")
	return false


func _transition(new_state: State, is_on_floor: bool) -> void:
	var old_state := current_state
	current_state = new_state

	# 착지 시 리셋
	if is_on_floor and old_state in [State.JUMP, State.FALL, State.DASH, State.LIGHT_DASH]:
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


func _get_max_air_jumps() -> int:
	return _max_air_jumps
