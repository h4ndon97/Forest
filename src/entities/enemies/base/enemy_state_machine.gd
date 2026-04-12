extends Node

## 적 AI 상태 머신.
## DORMANT(시간 정지) ↔ 활성 상태(IDLE~DEAD) 전환을 관리한다.

enum State { DORMANT, IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.DORMANT
var _target: Node2D = null
var _patrol_timer: float = 0.0
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var _enemy_root: Node2D
var _patrol_interval: float = 3.0
var _hurt_duration: float = 0.3


func setup(enemy_root: Node2D) -> void:
	_enemy_root = enemy_root
	var config: EnemyConfigData = EnemySystem.get_config()
	if config:
		_patrol_interval = config.patrol_interval
		_hurt_duration = config.hurt_duration


func is_active() -> bool:
	return current_state != State.DORMANT and current_state != State.DEAD


func activate() -> void:
	if current_state == State.DORMANT:
		_transition(State.IDLE)


func deactivate() -> void:
	if current_state != State.DEAD:
		_target = null
		_transition(State.DORMANT)


func update(delta: float) -> void:
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.PATROL:
			_update_patrol(delta)
		State.CHASE:
			_update_chase()
		State.ATTACK:
			_update_attack(delta)
		State.HURT:
			_update_hurt(delta)


func on_player_detected(player: Node2D) -> void:
	_target = player
	if current_state in [State.IDLE, State.PATROL]:
		_transition(State.CHASE)


func on_player_lost() -> void:
	_target = null
	if current_state == State.CHASE:
		_transition(State.IDLE)


func on_hurt() -> void:
	if current_state == State.DEAD:
		return
	_hurt_timer = _hurt_duration
	_transition(State.HURT)


func on_death() -> void:
	_transition(State.DEAD)


func get_target() -> Node2D:
	return _target


# --- 내부 ---

func _update_idle(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer >= _patrol_interval:
		_patrol_timer = 0.0
		_transition(State.PATROL)


func _update_patrol(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer >= _patrol_interval:
		_patrol_timer = 0.0
		_transition(State.IDLE)


func _update_chase() -> void:
	if not is_instance_valid(_target):
		_target = null
		_transition(State.IDLE)
		return

	var dist := _enemy_root.global_position.distance_to(_target.global_position)
	var stats_data: EnemyStatsData = _enemy_root.stats_data

	if dist <= stats_data.attack_range:
		_transition(State.ATTACK)
	elif dist > stats_data.lose_range:
		_target = null
		_transition(State.IDLE)


func _update_attack(delta: float) -> void:
	_attack_timer += delta
	var stats_data: EnemyStatsData = _enemy_root.stats_data

	if _attack_timer >= stats_data.attack_cooldown:
		_attack_timer = 0.0
		if not is_instance_valid(_target):
			_target = null
			_transition(State.IDLE)
			return

		var dist := _enemy_root.global_position.distance_to(_target.global_position)
		if dist > stats_data.attack_range:
			_transition(State.CHASE)


func _update_hurt(delta: float) -> void:
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		if is_instance_valid(_target):
			_transition(State.CHASE)
		else:
			_transition(State.IDLE)


func _transition(new_state: State) -> void:
	if new_state == current_state:
		return
	var old_state := current_state
	current_state = new_state

	# 상태 진입 초기화
	match new_state:
		State.IDLE:
			_patrol_timer = 0.0
		State.PATROL:
			_patrol_timer = 0.0
		State.ATTACK:
			_attack_timer = 0.0

	state_changed.emit(old_state, new_state)
