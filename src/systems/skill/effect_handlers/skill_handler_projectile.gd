extends RefCounted

## projectile 타입 스킬 핸들러. ProjectileSpec → CombatSystem.request_projectile.
## speed/lifetime은 ProjectileSpec 기본값 사용. 세부 튜닝 필요 시 SkillData 필드 추가로 대응.


static func handle(skill: SkillData, ctx: Dictionary) -> void:
	var caster: Node = ctx.get("caster")
	var movement: Node = ctx.get("movement")
	if caster == null or movement == null:
		push_warning("skill_handler_projectile: caster/movement missing")
		return
	if skill.projectile_scene == null:
		push_warning(
			"skill_handler_projectile: '%s' has no projectile_scene (에디터에서 할당 필요)" % skill.id
		)
		return
	if not EnemySystem.are_enemies_active():
		return
	if not (caster is Node2D):
		push_warning("skill_handler_projectile: caster must be Node2D")
		return

	var spawn_offset := Vector2(
		absf(skill.hitbox_offset.x) * movement.facing_direction,
		skill.hitbox_offset.y,
	)

	var spec := ProjectileSpec.new()
	spec.attacker = caster
	spec.source_group = "player_attack"
	spec.scene = skill.projectile_scene
	spec.spawn_position = (caster as Node2D).global_position + spawn_offset
	spec.direction = Vector2(movement.facing_direction, 0)
	spec.damage = skill.damage
	spec.attribute = skill.path
	spec.tags = PackedStringArray(["skill"])

	CombatSystem.request_projectile(spec)
