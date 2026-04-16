extends Node

## 플레이어 콤보 전투 컴포넌트.
## 4타 콤보 상태 머신, 히트박스 관리, 입력 버퍼링.

enum ComboState { IDLE, ATTACKING, WINDOW }

var _combo_count: int = 0
var _combo_state: int = ComboState.IDLE
var _input_buffered: bool = false
var _is_attacking: bool = false
var _enemies_active: bool = false

var _parent: CharacterBody2D
var _sprite: AnimatedSprite2D
var _movement: Node
var _config: CombatConfigData

var _attack_hitbox: Area2D
var _attack_shape: CollisionShape2D
var _hit_timer: Timer
var _window_timer: Timer
var _reset_timer: Timer


func setup(parent: CharacterBody2D, config: CombatConfigData) -> void:
	_parent = parent
	_sprite = parent.get_node("AnimatedSprite2D")
	_movement = parent.get_node("MovementComponent")
	_config = config

	_create_attack_hitbox()
	_create_timers()
	EventBus.player_died.connect(_on_player_died)


func update(input: Node, enemies_active: bool) -> void:
	_enemies_active = enemies_active

	match _combo_state:
		ComboState.IDLE:
			if input.attack_pressed:
				_start_hit(1)
		ComboState.ATTACKING:
			if input.attack_pressed:
				_input_buffered = true
		ComboState.WINDOW:
			if input.attack_pressed:
				_window_timer.stop()
				_start_hit(_combo_count + 1)


func is_attacking() -> bool:
	return _is_attacking


func get_combo_count() -> int:
	return _combo_count


# === 콤보 로직 ===


func _start_hit(hit_number: int) -> void:
	_combo_count = hit_number
	_combo_state = ComboState.ATTACKING
	_is_attacking = true
	_input_buffered = false

	# 히트박스 방향 설정 및 활성화
	var facing: int = _movement.facing_direction
	_attack_shape.position.x = absf(_config.hitbox_offset.x) * facing
	_attack_hitbox.set_meta("hit_number", _combo_count)
	var damage: float = CombatSystem.get_combo_damage(_combo_count)
	_attack_hitbox.set_meta("damage", damage)
	_attack_hitbox.set_meta("is_finish", _combo_count >= _config.combo_max_hits)
	if _enemies_active:
		_attack_hitbox.monitoring = true
		_attack_hitbox.monitorable = true

	# 애니메이션 재생
	var anim_name := "slash_%d" % hit_number
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation(anim_name):
			_sprite.play(anim_name)
		elif _sprite.sprite_frames.has_animation("slash"):
			_sprite.play("slash")

	_hit_timer.start()
	EventBus.combo_hit_landed.emit(hit_number)


func _on_hit_timer_timeout() -> void:
	# 히트박스 비활성화
	_attack_hitbox.monitoring = false
	_attack_hitbox.monitorable = false

	if _combo_count >= _config.combo_max_hits:
		# 피니시 완료 — 공격 플래그 즉시 해제, 리셋 타이머 후 콤보 초기화
		_is_attacking = false
		var attribute: String = _config.finish_attribute
		if SkillSystem:
			attribute = SkillSystem.get_finish_attribute()
		EventBus.combo_finished.emit(attribute)
		_combo_state = ComboState.IDLE
		_reset_timer.start()
		return

	# WINDOW 진입 시 버퍼 확인 — 버퍼된 입력이 있으면 즉시 다음 타 실행
	if _input_buffered:
		_input_buffered = false
		_start_hit(_combo_count + 1)
		return

	# 버퍼 없으면 입력 대기
	_combo_state = ComboState.WINDOW
	_window_timer.start()


func _on_window_timer_timeout() -> void:
	_reset_combo()


func _on_reset_timer_timeout() -> void:
	_reset_combo()


func _on_player_died() -> void:
	_hit_timer.stop()
	_window_timer.stop()
	_reset_timer.stop()
	_reset_combo()


func _reset_combo() -> void:
	_combo_count = 0
	_combo_state = ComboState.IDLE
	_input_buffered = false
	_is_attacking = false
	_attack_hitbox.monitoring = false
	_attack_hitbox.monitorable = false
	EventBus.combo_resetted.emit()


# === 히트박스/타이머 생성 ===


func _create_attack_hitbox() -> void:
	_attack_hitbox = Area2D.new()
	_attack_hitbox.name = "AttackHitbox"
	_attack_hitbox.collision_layer = Constants.LAYER_PLAYER_ATTACK
	_attack_hitbox.collision_mask = 0
	_attack_hitbox.monitoring = false
	_attack_hitbox.monitorable = false
	_attack_hitbox.add_to_group("player_attack")

	_attack_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _config.hitbox_size
	_attack_shape.shape = shape
	_attack_shape.position = _config.hitbox_offset
	_attack_hitbox.add_child(_attack_shape)

	_parent.add_child(_attack_hitbox)


func _create_timers() -> void:
	_hit_timer = Timer.new()
	_hit_timer.name = "HitTimer"
	_hit_timer.one_shot = true
	_hit_timer.wait_time = _config.hit_duration
	_hit_timer.timeout.connect(_on_hit_timer_timeout)
	add_child(_hit_timer)

	_window_timer = Timer.new()
	_window_timer.name = "WindowTimer"
	_window_timer.one_shot = true
	_window_timer.wait_time = _config.combo_window
	_window_timer.timeout.connect(_on_window_timer_timeout)
	add_child(_window_timer)

	_reset_timer = Timer.new()
	_reset_timer.name = "ResetTimer"
	_reset_timer.one_shot = true
	_reset_timer.wait_time = _config.combo_reset_time
	_reset_timer.timeout.connect(_on_reset_timer_timeout)
	add_child(_reset_timer)
