extends Node

## 플레이어 스킬 실행 컴포넌트.
## 4개 슬롯 입력을 읽어 SkillSystem을 통해 스킬을 발동한다.
## Phase 4-0 #1 Step 2.5: 자체 SkillHitbox 제거 → CombatSystem.request_attack(AttackSpec) 위임.
## 콤보·스킬이 단일 경로로 수렴(이중 히트박스 해소). 생명주기는 attack_requests가 관리.

const SkillData = preload("res://data/skills/skill_data.gd")

const EFFECT_ANIM_MAP := {
	"melee": "slash",
	"aoe": "slash",
}

var _parent: CharacterBody2D
var _movement: Node
var _sprite: AnimatedSprite2D
var _enemies_active: bool = false

## 사망 시 잔존 히트 방지용 안전장치 (Step 2 패턴 재사용).
var _current_attack_area: Area2D = null


func setup(parent: CharacterBody2D) -> void:
	_parent = parent
	_movement = parent.get_node("MovementComponent")
	_sprite = parent.get_node("AnimatedSprite2D")
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

	var res_data: Dictionary = TimeSystem.get_resource_data()
	if res_data.get("current", 0.0) < skill.time_cost:
		return

	EventBus.time_resource_consume_flat_requested.emit(skill.time_cost)
	SkillSystem.start_cooldown(slot_index)

	if _enemies_active:
		_request_attack(skill)

	_play_skill_animation(skill)
	EventBus.skill_used.emit(slot_index, skill.id)


func _request_attack(skill: SkillData) -> void:
	_cancel_current_attack()

	var spec := AttackSpec.new()
	spec.attacker = _parent
	spec.source_group = "player_attack"
	spec.damage = skill.damage
	spec.is_finish = false
	# 스킬 속성 체계는 #2 SkillExec / #3 속성 피니시에서 도입. 본 Phase는 "none" 유지.
	spec.attribute = "none"
	spec.active_duration = skill.active_duration
	spec.tags = PackedStringArray(["skill"])
	spec.skill_id = skill.id

	match skill.effect_type:
		"aoe":
			spec.shape_type = "circle"
			spec.circle_radius = skill.aoe_radius
		_:
			spec.shape_type = "rect"
			spec.hitbox_size = skill.hitbox_size
			spec.hitbox_offset = Vector2(
				absf(skill.hitbox_offset.x) * _movement.facing_direction,
				skill.hitbox_offset.y,
			)

	_current_attack_area = CombatSystem.request_attack(spec)


func _play_skill_animation(skill: SkillData) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	# 스킬별 전용 애니메이션 우선 → effect_type 매핑 → slash fallback
	var anim_name := "skill_%s" % skill.id
	if not _sprite.sprite_frames.has_animation(anim_name):
		anim_name = EFFECT_ANIM_MAP.get(skill.effect_type, "slash")
	if _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null


func _on_player_died() -> void:
	_cancel_current_attack()
