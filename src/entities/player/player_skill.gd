extends Node

## 플레이어 스킬 실행 컴포넌트.
## 4개 슬롯 입력을 읽어 SkillSystem을 통해 스킬을 발동한다.
## 히트박스를 생성/관리하고 effect_type에 따라 형상을 전환한다.

const SkillData = preload("res://data/skills/skill_data.gd")

const EFFECT_ANIM_MAP := {
	"melee": "slash",
	"aoe": "slash",
}

var _parent: CharacterBody2D
var _movement: Node
var _sprite: AnimatedSprite2D
var _enemies_active: bool = false

var _skill_hitbox: Area2D
var _skill_shape: CollisionShape2D
var _active_timer: Timer
var _is_active: bool = false


func setup(parent: CharacterBody2D) -> void:
	_parent = parent
	_movement = parent.get_node("MovementComponent")
	_sprite = parent.get_node("AnimatedSprite2D")
	_create_hitbox()
	_create_timer()
	EventBus.player_died.connect(_on_player_died)


func update(input: Node, enemies_active: bool) -> void:
	_enemies_active = enemies_active

	if input.skill_1_pressed:
		_try_use_skill(0)
	if input.skill_2_pressed:
		_try_use_skill(1)
	if input.skill_3_pressed:
		_try_use_skill(2)
	if input.skill_4_pressed:
		_try_use_skill(3)


# === 스킬 실행 ===


func _try_use_skill(slot_index: int) -> void:
	if not SkillSystem.can_use_skill(slot_index):
		return

	var skill: SkillData = SkillSystem.get_equipped_skill(slot_index)
	if skill == null:
		return

	# 시간 자원 확인
	var res_data: Dictionary = TimeSystem.get_resource_data()
	if res_data.get("current", 0.0) < skill.time_cost:
		return

	# 시간 자원 소비
	EventBus.time_resource_consume_flat_requested.emit(skill.time_cost)

	# 쿨다운 시작
	SkillSystem.start_cooldown(slot_index)

	# 히트박스 설정 및 활성화
	_configure_hitbox(skill)
	_activate_hitbox(skill)
	_play_skill_animation(skill)

	EventBus.skill_used.emit(slot_index, skill.id)


func _configure_hitbox(skill: SkillData) -> void:
	_skill_hitbox.set_meta("damage", skill.damage)
	_skill_hitbox.set_meta("is_finish", false)
	_skill_hitbox.set_meta("is_skill", true)
	_skill_hitbox.set_meta("skill_path", skill.path)

	match skill.effect_type:
		"aoe":
			var circle := CircleShape2D.new()
			circle.radius = skill.aoe_radius
			_skill_shape.shape = circle
			_skill_shape.position = Vector2.ZERO
		_:
			var rect := RectangleShape2D.new()
			rect.size = skill.hitbox_size
			_skill_shape.shape = rect
			var facing: int = _movement.facing_direction
			_skill_shape.position = Vector2(
				absf(skill.hitbox_offset.x) * facing, skill.hitbox_offset.y
			)


func _activate_hitbox(skill: SkillData) -> void:
	if _enemies_active:
		_skill_hitbox.monitoring = true
		_skill_hitbox.monitorable = true
	_is_active = true
	_active_timer.wait_time = skill.active_duration
	_active_timer.start()


func _deactivate_hitbox() -> void:
	_skill_hitbox.monitoring = false
	_skill_hitbox.monitorable = false
	_is_active = false


func _play_skill_animation(skill: SkillData) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	# 스킬별 전용 애니메이션 우선 → effect_type 매핑 → slash fallback
	var anim_name := "skill_%s" % skill.id
	if not _sprite.sprite_frames.has_animation(anim_name):
		anim_name = EFFECT_ANIM_MAP.get(skill.effect_type, "slash")
	if _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)


# === 생성 ===


func _create_hitbox() -> void:
	_skill_hitbox = Area2D.new()
	_skill_hitbox.name = "SkillHitbox"
	_skill_hitbox.collision_layer = Constants.LAYER_PLAYER_ATTACK
	_skill_hitbox.collision_mask = 0
	_skill_hitbox.monitoring = false
	_skill_hitbox.monitorable = false
	_skill_hitbox.add_to_group("player_attack")

	_skill_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 28)
	_skill_shape.shape = shape
	_skill_hitbox.add_child(_skill_shape)

	_parent.add_child(_skill_hitbox)


func _create_timer() -> void:
	_active_timer = Timer.new()
	_active_timer.name = "SkillActiveTimer"
	_active_timer.one_shot = true
	_active_timer.timeout.connect(_on_active_timer_timeout)
	add_child(_active_timer)


# === 콜백 ===


func _on_active_timer_timeout() -> void:
	_deactivate_hitbox()


func _on_player_died() -> void:
	_active_timer.stop()
	_deactivate_hitbox()
