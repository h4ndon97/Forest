extends Node

## 보스 상태 머신.
## EnemyStateMachine 기반 + 보스 전용 INTRO/PHASE_TRANSITION/DEFEATED.
## 보스는 순찰 없음 — IDLE에서 타깃 있으면 즉시 CHASE.

signal state_changed(old_state: int, new_state: int)
signal intro_finished
signal phase_transition_finished

enum State { DORMANT, INTRO, IDLE, CHASE, ATTACK, PHASE_TRANSITION, HURT, DEFEATED }

var current_state: State = State.DORMANT

var _target: Node2D = null
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var _intro_timer: float = 0.0
var _transition_timer: float = 0.0
var _boss_root: Node = null
var _hurt_duration: float = 0.3
var _intro_duration: float = 1.5
var _transition_duration: float = 1.8


func setup(boss_root: Node) -> void:
	_boss_root = boss_root
	var config: EnemyConfigData = EnemySystem.get_config()
	if config:
		_hurt_duration = config.hurt_duration
	if boss_root and boss_root.boss_data:
		_intro_duration = boss_root.boss_data.intro_duration
		_transition_duration = boss_root.boss_data.phase_transition_duration


func is_active() -> bool:
	return current_state != State.DORMANT and current_state != State.DEFEATED


## 무적 상태 (피격 무시): INTRO, PHASE_TRANSITION, DEFEATED
func is_invincible() -> bool:
	return current_state in [State.INTRO, State.PHASE_TRANSITION, State.DEFEATED]


func activate() -> void:
	if current_state == State.DORMANT:
		_intro_timer = 0.0
		_transition(State.INTRO)


func deactivate() -> void:
	if current_state != State.DEFEATED:
		_target = null
		_transition(State.DORMANT)


func update(delta: float) -> void:
	match current_state:
		State.INTRO:
			_update_intro(delta)
		State.IDLE:
			_update_idle()
		State.CHASE:
			_update_chase()
		State.ATTACK:
			_update_attack(delta)
		State.PHASE_TRANSITION:
			_update_phase_transition(delta)
		State.HURT:
			_update_hurt(delta)


func on_player_detected(player: Node2D) -> void:
	_target = player
	if current_state == State.IDLE:
		_transition(State.CHASE)


func on_player_lost() -> void:
	_target = null
	if current_state == State.CHASE:
		_transition(State.IDLE)


func on_hurt() -> void:
	if is_invincible() or current_state == State.DEFEATED:
		return
	_hurt_timer = _hurt_duration
	_transition(State.HURT)


func on_death() -> void:
	_transition(State.DEFEATED)


## 페이즈 컨트롤러가 호출 — 무적/이동 정지 상태로 전환
func enter_phase_transition() -> void:
	_transition_timer = 0.0
	_transition(State.PHASE_TRANSITION)


func get_target() -> Node2D:
	return _target


# --- 내부 ---

func _update_intro(delta: float) -> void:
	_intro_timer += delta
	if _intro_timer >= _intro_duration:
		_intro_timer = 0.0
		intro_finished.emit()
		_transition(State.IDLE)


func _update_idle() -> void:
	if is_instance_valid(_target):
		_transition(State.CHASE)


func _update_chase() -> void:
	if not is_instance_valid(_target):
		_target = null
		_transition(State.IDLE)
		return
	var stats_data: EnemyStatsData = _boss_root.boss_data.base_stats
	var dist: float = _boss_root.global_position.distance_to(_target.global_position)
	if dist <= stats_data.attack_range:
		_transition(State.ATTACK)
	elif dist > stats_data.lose_range:
		_target = null
		_transition(State.IDLE)


func _update_attack(delta: float) -> void:
	_attack_timer += delta
	var stats_data: EnemyStatsData = _boss_root.boss_data.base_stats
	if _attack_timer >= stats_data.attack_cooldown:
		_attack_timer = 0.0
		if not is_instance_valid(_target):
			_target = null
			_transition(State.IDLE)
			return
		var dist: float = _boss_root.global_position.distance_to(_target.global_position)
		if dist > stats_data.attack_range:
			_transition(State.CHASE)


func _update_phase_transition(delta: float) -> void:
	_transition_timer += delta
	if _transition_timer >= _transition_duration:
		_transition_timer = 0.0
		phase_transition_finished.emit()
		_transition(State.IDLE)


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
	var old_state: State = current_state
	current_state = new_state
	match new_state:
		State.ATTACK:
			_attack_timer = 0.0
		State.INTRO:
			_intro_timer = 0.0
		State.PHASE_TRANSITION:
			_transition_timer = 0.0
	state_changed.emit(old_state, new_state)
