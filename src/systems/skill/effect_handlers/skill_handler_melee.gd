extends RefCounted

## melee 타입 스킬 핸들러. AttackSpec(rect) → CombatSystem.request_attack.
## 정적 호출 전용. SkillExecutor가 preload하여 handle()을 호출한다.

## 임시 스프라이트가 콤보 slash와 동일해 시각 구분이 없는 동안의 가교 이펙트.
## 진짜 스킬 애니메이션 또는 Pass 5 Step 3 슬래시 트레일 도입 시 청산 대상.
const CAST_PARTICLE_CATEGORY: StringName = &"shadow"


static func handle(skill: SkillData, ctx: Dictionary) -> void:
	var caster: Node = ctx.get("caster")
	var movement: Node = ctx.get("movement")
	if caster == null or movement == null:
		push_warning("skill_handler_melee: caster/movement missing")
		return

	# 시전 단서 — enemies_active 가드 밖에서 호출(낮/컷신 중 시전에서도 시각 단서 유지,
	# SkillExecutor의 애니/쿨다운/자원 소모와 일관).
	_emit_cast_effects(skill, ctx, movement)

	# 낮/컷신 중(enemies_active=false)에도 스킬 발동은 허용하되 히트박스는 생성하지 않는다.
	if not EnemySystem.are_enemies_active():
		return

	var spec := AttackSpec.new()
	spec.attacker = caster
	spec.source_group = "player_attack"
	spec.damage = skill.damage
	spec.active_duration = skill.active_duration
	spec.shape_type = "rect"
	spec.hitbox_size = skill.hitbox_size
	spec.hitbox_offset = Vector2(
		absf(skill.hitbox_offset.x) * movement.facing_direction,
		skill.hitbox_offset.y,
	)
	spec.attribute = skill.path
	spec.is_finish = false
	spec.tags = PackedStringArray(["skill"])
	spec.skill_id = skill.id

	CombatSystem.request_attack(spec)


static func _emit_cast_effects(skill: SkillData, ctx: Dictionary, movement: Node) -> void:
	var caster_2d: Node2D = ctx.get("caster") as Node2D
	if caster_2d == null:
		return
	var burst_pos: Vector2 = (
		caster_2d.global_position
		+ Vector2(
			absf(skill.hitbox_offset.x) * movement.facing_direction,
			skill.hitbox_offset.y,
		)
	)
	EffectsSystem.request_hit_particle(burst_pos, CAST_PARTICLE_CATEGORY, true, skill.path)
	var sprite: CanvasItem = ctx.get("sprite") as CanvasItem
	if sprite != null:
		EffectsSystem.request_hit_flash(sprite, EffectsSystem.get_finish_color(skill.path))
	EffectsSystem.request_shake(EffectsSystem.PRESET_LIGHT)
