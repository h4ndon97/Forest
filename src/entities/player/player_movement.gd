extends Node

## 현재 상태와 입력 의도를 받아 velocity를 계산한다.
## move_and_slide()는 루트(player.gd)에서 호출한다.

const State = preload("res://src/entities/player/player_state_machine.gd").State

var stats: PlayerStatsData
var facing_direction: int = 1  # 1 = 오른쪽, -1 = 왼쪽
var _attack_movement_factor: float = 0.4

signal facing_changed(direction: int)


func setup(player_stats: PlayerStatsData, attack_movement_factor: float = 0.4) -> void:
	stats = player_stats
	_attack_movement_factor = attack_movement_factor


func calculate_velocity(
	current_state: int,
	input: Node,
	velocity: Vector2,
	is_on_floor: bool,
	delta: float,
	is_attacking: bool = false
) -> Vector2:
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) as float

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)
			velocity.y = _apply_gravity(velocity.y, gravity, delta, current_state)

		State.RUN:
			velocity.x = input.move_direction * stats.run_speed
			_update_facing(input.move_direction)
			velocity.y = _apply_gravity(velocity.y, gravity, delta, current_state)

		State.JUMP:
			velocity.x = input.move_direction * stats.run_speed
			if input.move_direction != 0.0:
				_update_facing(input.move_direction)
			# 점프 시작은 player.gd에서 velocity.y 설정
			velocity.y = _apply_gravity(velocity.y, gravity, delta, current_state)
			# 가변 점프: 키를 놓으면 상승 감소
			if input.jump_released and velocity.y < 0.0:
				velocity.y *= stats.jump_cut_multiplier

		State.FALL:
			velocity.x = input.move_direction * stats.run_speed
			if input.move_direction != 0.0:
				_update_facing(input.move_direction)
			velocity.y = _apply_gravity(velocity.y, gravity, delta, current_state)

		State.DASH:
			velocity = Vector2(facing_direction * stats.dash_speed, 0.0)

		State.LIGHT_DASH:
			velocity = Vector2(facing_direction * stats.light_dash_speed, 0.0)

	# 공격 중 수평 이동 감속 (DASH/LIGHT_DASH 제외)
	if is_attacking and current_state != State.DASH and current_state != State.LIGHT_DASH:
		velocity.x *= _attack_movement_factor

	# 바닥에 서 있을 때 중력 리셋
	if is_on_floor and velocity.y > 0.0:
		velocity.y = 0.0

	return velocity


func _apply_gravity(vel_y: float, gravity: float, delta: float, current_state: int) -> float:
	var scale := stats.gravity_scale
	if current_state == State.FALL or vel_y > 0.0:
		scale = stats.fall_gravity_scale
	return vel_y + gravity * scale * delta


func _update_facing(move_dir: float) -> void:
	var new_dir := int(sign(move_dir))
	if new_dir != 0 and new_dir != facing_direction:
		facing_direction = new_dir
		facing_changed.emit(facing_direction)
