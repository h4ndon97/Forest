extends Node

## 플레이어 행동 상태를 관리하고 전이를 결정한다.

enum State { IDLE, RUN, JUMP, FALL, DASH }

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.IDLE
var air_jump_count: int = 0
var can_dash: bool = true
var coyote_active: bool = false
var dash_active: bool = false

var _coyote_timer: Timer
var _dash_duration_timer: Timer
var _dash_cooldown_timer: Timer
var _max_air_jumps: int = 1


func setup(coyote_timer: Timer, dash_duration_timer: Timer, dash_cooldown_timer: Timer, max_air_jumps: int = 1) -> void:
	_coyote_timer = coyote_timer
	_dash_duration_timer = dash_duration_timer
	_dash_cooldown_timer = dash_cooldown_timer
	_max_air_jumps = max_air_jumps

	_coyote_timer.timeout.connect(_on_coyote_timeout)
	_dash_duration_timer.timeout.connect(_on_dash_duration_timeout)
	_dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)


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

	if new_state != current_state:
		_transition(new_state, is_on_floor)


func _update_idle(input: Node, is_on_floor: bool) -> State:
	if input.dash_pressed and can_dash:
		return State.DASH
	if input.jump_pressed and is_on_floor:
		return State.JUMP
	if not is_on_floor:
		_start_coyote()
		return State.FALL
	if input.move_direction != 0.0:
		return State.RUN
	return State.IDLE


func _update_run(input: Node, is_on_floor: bool) -> State:
	if input.dash_pressed and can_dash:
		return State.DASH
	if input.jump_pressed and is_on_floor:
		return State.JUMP
	if not is_on_floor:
		_start_coyote()
		return State.FALL
	if input.move_direction == 0.0:
		return State.IDLE
	return State.RUN


func _update_jump(input: Node, velocity: Vector2) -> State:
	if input.dash_pressed and can_dash:
		return State.DASH
	if input.jump_pressed and air_jump_count < _get_max_air_jumps():
		air_jump_count += 1
		return State.JUMP  # 2단 점프: 재진입
	if velocity.y >= 0.0:
		return State.FALL
	return State.JUMP


func _update_fall(input: Node, is_on_floor: bool) -> State:
	if input.dash_pressed and can_dash:
		return State.DASH
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


func _transition(new_state: State, is_on_floor: bool) -> void:
	var old_state := current_state
	current_state = new_state

	# 착지 시 리셋
	if is_on_floor and old_state in [State.JUMP, State.FALL, State.DASH]:
		air_jump_count = 0
		can_dash = true

	# 상태 진입 처리
	match new_state:
		State.DASH:
			dash_active = true
			can_dash = false
			_dash_duration_timer.start()
			_dash_cooldown_timer.start()

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


func _get_max_air_jumps() -> int:
	return _max_air_jumps
