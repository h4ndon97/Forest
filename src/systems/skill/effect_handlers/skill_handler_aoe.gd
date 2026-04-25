extends RefCounted

## aoe 타입 스킬 핸들러. AttackSpec(circle) → CombatSystem.request_attack.
## 정적 호출 전용. SkillExecutor가 preload하여 handle()을 호출한다.


static func handle(skill: SkillData, ctx: Dictionary) -> void:
	var caster: Node = ctx.get("caster")
	if caster == null:
		push_warning("skill_handler_aoe: caster missing")
		return
	# 낮/컷신 중(enemies_active=false)에도 스킬 발동은 허용하되 히트박스는 생성하지 않는다.
	if not EnemySystem.are_enemies_active():
		return

	var spec := AttackSpec.new()
	spec.attacker = caster
	spec.source_group = "player_attack"
	spec.damage = skill.damage
	spec.active_duration = skill.active_duration
	spec.shape_type = "circle"
	spec.circle_radius = skill.aoe_radius
	# AoE는 방향 무관. hitbox_offset은 caster 중심 기준 0 고정.
	spec.hitbox_offset = Vector2.ZERO
	spec.attribute = skill.path
	spec.is_finish = false
	spec.tags = PackedStringArray(["skill"])
	spec.skill_id = skill.id

	CombatSystem.request_attack(spec)
