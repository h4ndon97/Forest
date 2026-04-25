extends RefCounted

## melee 타입 스킬 핸들러. AttackSpec(rect) → CombatSystem.request_attack.
## 정적 호출 전용. SkillExecutor가 preload하여 handle()을 호출한다.


static func handle(skill: SkillData, ctx: Dictionary) -> void:
	var caster: Node = ctx.get("caster")
	var movement: Node = ctx.get("movement")
	if caster == null or movement == null:
		push_warning("skill_handler_melee: caster/movement missing")
		return
	# 낮/컷신 중(enemies_active=false)에도 스킬 발동은 허용하되 히트박스는 생성하지 않는다.
	# SkillExecutor가 애니메이션/쿨다운/자원 소모를 이미 처리 중.
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
