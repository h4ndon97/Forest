extends Node

## 적 이동 계산 컴포넌트.
## 상태에 따라 순찰/추적/정지 velocity를 계산한다.

const EnemyStateMachine = preload("res://src/entities/enemies/base/enemy_state_machine.gd")
const STATE = EnemyStateMachine.State

var facing: float = -1.0  # -1 = 왼쪽, 1 = 오른쪽
var _stats_data: EnemyStatsData
var _stats_comp: Node
var _patrol_direction: float = -1.0


func setup(stats_data: EnemyStatsData, stats_comp: Node) -> void:
	_stats_data = stats_data
	_stats_comp = stats_comp
	_patrol_direction = [-1.0, 1.0].pick_random()


func calculate_velocity(
	state: int,
	target: Node2D,
	current_velocity: Vector2,
	global_pos: Vector2,
	_is_on_floor: bool,
	delta: float
) -> Vector2:
	if _stats_data != null and _stats_data.movement_profile == "airborne_homing":
		return _calculate_airborne(state, target, current_velocity, global_pos, delta)

	var vel := current_velocity
	# 중력은 base_enemy._physics_process()에서 이미 적용됨 — 여기서는 X축만 처리

	match state:
		STATE.DORMANT, STATE.IDLE, STATE.HURT, STATE.DEAD:
			vel.x = move_toward(vel.x, 0.0, _stats_comp.get_speed() * delta * 8.0)

		STATE.PATROL:
			vel.x = _patrol_direction * _stats_comp.get_patrol_speed()
			facing = _patrol_direction

		STATE.CHASE:
			if is_instance_valid(target):
				var dir: float = sign(target.global_position.x - global_pos.x)
				vel.x = dir * _stats_comp.get_speed()
				if dir != 0.0:
					facing = dir

		STATE.ATTACK:
			vel.x = move_toward(vel.x, 0.0, _stats_comp.get_speed() * delta * 8.0)
			if is_instance_valid(target):
				facing = signf(target.global_position.x - global_pos.x)

	return vel


## 순찰 방향을 반전한다 (벽 감지 등에서 호출).
func flip_patrol() -> void:
	_patrol_direction *= -1.0


# --- 공중 호밍 (airborne_homing) ---


func _calculate_airborne(
	state: int, target: Node2D, current_velocity: Vector2, global_pos: Vector2, delta: float
) -> Vector2:
	var vel := current_velocity
	var max_speed: float = _stats_data.homing_max_speed
	var turn_rate: float = _stats_data.homing_turn_rate
	var lerp_factor: float = clampf(turn_rate * delta, 0.0, 1.0)

	match state:
		STATE.DORMANT, STATE.IDLE, STATE.PATROL, STATE.HURT, STATE.DEAD:
			vel = vel.lerp(Vector2.ZERO, lerp_factor)

		STATE.CHASE:
			if is_instance_valid(target):
				var desired: Vector2 = (
					(target.global_position - global_pos).normalized() * max_speed
				)
				vel = vel.lerp(desired, lerp_factor)
				if absf(desired.x) > 0.01:
					facing = signf(desired.x)

		STATE.ATTACK:
			vel = vel.lerp(Vector2.ZERO, lerp_factor)
			if is_instance_valid(target):
				facing = signf(target.global_position.x - global_pos.x)

	return vel
