extends Node

## 플레이어 콤보 전투 컴포넌트.
## 4타 콤보 상태 머신, 입력 버퍼링.
## Phase 4-0 #1 Step 2: 자체 Area2D 관리 → CombatSystem.request_attack(AttackSpec) 위임.
## Phase 4-0 #3: 피니시(4타) 발동 시 FinishStrategy 패턴으로 속성 분기(light/shadow/hybrid/neutral).
## 히트박스 생명주기는 CombatSystem.attack_requests가 spec.active_duration 기반으로 관리.

enum ComboState { IDLE, ATTACKING, WINDOW }

const FinishNeutralScript = preload("res://src/entities/player/finish/finish_neutral.gd")
const FinishHybridScript = preload("res://src/entities/player/finish/finish_hybrid.gd")
const FinishLightScript = preload("res://src/entities/player/finish/finish_light.gd")
const FinishShadowScript = preload("res://src/entities/player/finish/finish_shadow.gd")

var _combo_count: int = 0
var _combo_state: int = ComboState.IDLE
var _input_buffered: bool = false
var _is_attacking: bool = false
var _enemies_active: bool = false

var _parent: CharacterBody2D
var _sprite: AnimatedSprite2D
var _movement: Node
var _config: CombatConfigData

## 사망/리셋 시 잔존 히트 방지용 안전장치 — active_duration 만료 전 즉시 cancel.
var _current_attack_area: Area2D = null

var _hit_timer: Timer
var _window_timer: Timer
var _reset_timer: Timer


func setup(parent: CharacterBody2D, config: CombatConfigData) -> void:
	_parent = parent
	_sprite = parent.get_node("AnimatedSprite2D")
	_movement = parent.get_node("MovementComponent")
	_config = config
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

	if _enemies_active:
		_cancel_current_attack()
		if _combo_count >= _config.combo_max_hits:
			_execute_finish()
		else:
			_execute_normal_hit()

	var anim_name := "slash_%d" % hit_number
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation(anim_name):
			_sprite.play(anim_name)
		elif _sprite.sprite_frames.has_animation("slash"):
			_sprite.play("slash")

	_hit_timer.start()
	EventBus.combo_hit_landed.emit(hit_number)


func _execute_normal_hit() -> void:
	var spec := AttackSpec.new()
	spec.attacker = _parent
	spec.source_group = "player_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = _config.hitbox_size
	spec.hitbox_offset = Vector2(
		absf(_config.hitbox_offset.x) * _movement.facing_direction,
		_config.hitbox_offset.y,
	)
	spec.active_duration = _config.hit_duration
	spec.damage = CombatSystem.get_combo_damage(_combo_count)
	spec.is_finish = false
	spec.attribute = "none"
	spec.tags = PackedStringArray(["combo", "hit_%d" % _combo_count])
	_current_attack_area = CombatSystem.request_attack(spec)


func _execute_finish() -> void:
	var attribute: String = _resolve_finish_attribute()
	var ctx: Dictionary = {
		FinishStrategy.KEY_PLAYER: _parent,
		FinishStrategy.KEY_MOVEMENT: _movement,
		FinishStrategy.KEY_HEALTH: _parent.get_node_or_null("Health"),
		FinishStrategy.KEY_DAMAGE: CombatSystem.get_combo_damage(_combo_count),
		FinishStrategy.KEY_CONFIG: _config,
		FinishStrategy.KEY_ATTRIBUTE: attribute,
	}
	# 피니시는 전략 내부에서 다단히트(shadow)를 포함할 수 있어 단일 Area2D 추적 불가.
	# _current_attack_area는 normal hit 전용으로 유지되며, 피니시는 attack_requests 자동 만료에 위임.
	match attribute:
		"light":
			FinishLightScript.execute(ctx)
		"shadow":
			FinishShadowScript.execute(ctx)
		"hybrid":
			FinishHybridScript.execute(ctx)
		_:
			FinishNeutralScript.execute(ctx)


# 히트박스 OFF는 CombatSystem.attack_requests가 처리. 본 콜백은 상태 전이 전용.
func _on_hit_timer_timeout() -> void:
	if _combo_count >= _config.combo_max_hits:
		_is_attacking = false
		EventBus.combo_finished.emit(_resolve_finish_attribute())
		_combo_state = ComboState.IDLE
		_reset_timer.start()
		return
	if _input_buffered:
		_input_buffered = false
		_start_hit(_combo_count + 1)
		return
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


func _resolve_finish_attribute() -> String:
	if SkillSystem:
		return SkillSystem.get_finish_attribute()
	return _config.finish_attribute


func _reset_combo() -> void:
	_combo_count = 0
	_combo_state = ComboState.IDLE
	_input_buffered = false
	_is_attacking = false
	_cancel_current_attack()
	EventBus.combo_resetted.emit()


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null


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
