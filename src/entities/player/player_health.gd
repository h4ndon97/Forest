extends Node

## 플레이어 HP / 무적 / 사망 / 자동 회복 관리.
## 허트박스 생성 및 적 공격 감지 처리.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

var max_hp: float
var current_hp: float
var _is_invincible: bool = false
var _is_knocked_back: bool = false
var _parent: CharacterBody2D
var _hurtbox: Area2D
var _invincible_timer: Timer
var _knockback_timer: Timer
var _auto_heal_timer: Timer
var _config: CombatConfigData


func setup(parent: CharacterBody2D, config: CombatConfigData) -> void:
	_parent = parent
	_config = config
	max_hp = config.player_max_hp
	current_hp = max_hp

	_create_hurtbox()
	_create_invincible_timer()
	_create_knockback_timer()
	_create_auto_heal_timer()

	EventBus.player_respawned.connect(_on_respawned)
	EventBus.full_recovery_requested.connect(_on_full_recovery)
	EventBus.player_died.connect(_on_player_died_heal)
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.health_changed.emit(current_hp, max_hp)


func take_damage(amount: float) -> void:
	if _is_invincible:
		return

	current_hp = maxf(current_hp - amount, 0.0)
	EventBus.health_changed.emit(current_hp, max_hp)
	EventBus.damage_received.emit(amount)

	if current_hp <= 0.0:
		_hurtbox.monitoring = false
		EventBus.player_died.emit()
		return

	_start_invincibility()


# === 내부 ===


func _create_hurtbox() -> void:
	_hurtbox = Area2D.new()
	_hurtbox.name = "PlayerHurtbox"
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = Constants.LAYER_ENEMY_ATTACK
	_hurtbox.monitoring = true
	_hurtbox.monitorable = false

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _config.hurtbox_size
	shape_node.shape = shape
	shape_node.position = _config.hurtbox_offset
	_hurtbox.add_child(shape_node)

	_hurtbox.area_entered.connect(_on_enemy_attack_hit)
	_parent.add_child(_hurtbox)


func is_knocked_back() -> bool:
	return _is_knocked_back


func _create_invincible_timer() -> void:
	_invincible_timer = Timer.new()
	_invincible_timer.name = "InvincibleTimer"
	_invincible_timer.one_shot = true
	_invincible_timer.wait_time = _config.invincible_duration
	_invincible_timer.timeout.connect(func(): _is_invincible = false)
	add_child(_invincible_timer)


func _create_knockback_timer() -> void:
	_knockback_timer = Timer.new()
	_knockback_timer.name = "KnockbackTimer"
	_knockback_timer.one_shot = true
	_knockback_timer.wait_time = _config.knockback_duration
	_knockback_timer.timeout.connect(func(): _is_knocked_back = false)
	add_child(_knockback_timer)


func _start_invincibility() -> void:
	_is_invincible = true
	_invincible_timer.start()


func _on_enemy_attack_hit(area: Area2D) -> void:
	if _is_invincible:
		return
	var enemy := area.get_parent()
	if not enemy.is_in_group("enemies"):
		return
	var enemy_stats := enemy.get_node_or_null("Stats")
	if enemy_stats and enemy_stats.has_method("get_attack"):
		take_damage(enemy_stats.get_attack())
		if current_hp > 0.0:
			_apply_knockback(enemy)


func _apply_knockback(enemy: Node2D) -> void:
	var dir: float = signf(_parent.global_position.x - enemy.global_position.x)
	if dir == 0.0:
		dir = 1.0
	_parent.velocity.x = dir * _config.knockback_force
	_parent.velocity.y = _config.knockback_up_force
	_is_knocked_back = true
	_knockback_timer.start()


func _on_full_recovery() -> void:
	_reset_health_state()


func _on_respawned(_position: Vector2) -> void:
	_reset_health_state()


func _reset_health_state() -> void:
	current_hp = max_hp
	_is_invincible = false
	_is_knocked_back = false
	_knockback_timer.stop()
	_stop_auto_healing()
	_hurtbox.monitoring = true
	EventBus.health_changed.emit(current_hp, max_hp)


# === 자동 회복 ===


func _create_auto_heal_timer() -> void:
	_auto_heal_timer = Timer.new()
	_auto_heal_timer.name = "AutoHealTimer"
	_auto_heal_timer.one_shot = false
	_auto_heal_timer.wait_time = _config.auto_heal_interval
	_auto_heal_timer.timeout.connect(_on_auto_heal_tick)
	add_child(_auto_heal_timer)


func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	if new_state == TimeStateMachine.TimeState.STOPPED and current_hp < max_hp and current_hp > 0.0:
		_start_auto_healing()
	else:
		_stop_auto_healing()


func _start_auto_healing() -> void:
	if _auto_heal_timer.is_stopped():
		_auto_heal_timer.start()


func _stop_auto_healing() -> void:
	_auto_heal_timer.stop()


func _on_auto_heal_tick() -> void:
	if current_hp <= 0.0 or current_hp >= max_hp:
		_stop_auto_healing()
		return
	current_hp = minf(current_hp + _config.auto_heal_amount, max_hp)
	EventBus.health_changed.emit(current_hp, max_hp)
	if current_hp >= max_hp:
		_stop_auto_healing()


func _on_player_died_heal() -> void:
	_stop_auto_healing()
