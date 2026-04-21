class_name DamageResolver
extends RefCounted

## hurtbox 접촉 시 데미지·이펙트·이벤트 분배를 전담하는 정적 헬퍼.
##
## Step 1(본 커밋)에서는 scaffolding만 작성 — 어떤 엔티티도 resolve_hit()을 호출하지 않는다.
## Step 6(기존 base_enemy._on_hurtbox_area_entered 이동)에서 다음 두 변경을 동시 수행:
##   (a) EffectsSystem 직접 호출 → EventBus.hit_flash_requested/hitstop_requested emit
##   (b) base_enemy/base_boss._on_hurtbox_area_entered → DamageResolver.resolve_hit(self, area)
##
## 현재 본체 로직은 base_enemy.gd:244-267의 동작을 그대로 복제 — Step 6의 시그널 전환은
## emit 구조만 바꿀 뿐 호출 흐름은 변경 없음. 이를 위해 EffectsSystem 직접 호출 유지.

const _META_ATTACK_SPEC := "attack_spec"
const _DAMAGE_NUMBER_OFFSET := Vector2(0, -8)


## hurtbox에 들어온 attacker_area의 AttackSpec을 읽어 target에 데미지·이펙트 적용.
## 호출 시점: Step 6 이후 base_enemy._on_hurtbox_area_entered 내부.
static func resolve_hit(target: Node, attacker_area: Area2D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(attacker_area):
		return
	if not attacker_area.has_meta(_META_ATTACK_SPEC):
		return
	var spec: AttackSpec = attacker_area.get_meta(_META_ATTACK_SPEC) as AttackSpec
	if spec == null:
		return

	_apply_effects(target, spec)
	_apply_damage(target, spec)
	_emit_damage_dealt(target, spec)


static func _apply_effects(target: Node, spec: AttackSpec) -> void:
	var flash_color: Color = Color(0.0, 0.0, 0.0, 0.0)
	if spec.is_finish and spec.attribute != "none" and spec.attribute != "":
		flash_color = EffectsSystem.get_finish_color(spec.attribute)
	_play_target_flash(target, flash_color)

	# TODO(Step 6): 아래 2건을 EventBus.hit_flash_requested/hitstop_requested emit으로 전환.
	if spec.is_finish:
		EffectsSystem.request_shake(EffectsSystem.PRESET_FINISH)
		EffectsSystem.request_hitstop(EffectsSystem.PRESET_FINISH)
	else:
		EffectsSystem.request_shake(EffectsSystem.PRESET_LIGHT)
		EffectsSystem.request_hitstop(EffectsSystem.PRESET_HIT)

	if target is Node2D:
		var world_pos: Vector2 = (target as Node2D).global_position + _DAMAGE_NUMBER_OFFSET
		var category: StringName = _resolve_enemy_category(target)
		EffectsSystem.request_hit_particle(world_pos, category, spec.is_finish, spec.attribute)


static func _apply_damage(target: Node, spec: AttackSpec) -> void:
	if target.has_method("take_damage"):
		target.take_damage(spec.damage)


static func _emit_damage_dealt(target: Node, spec: AttackSpec) -> void:
	var target_id: int = _resolve_target_id(target)
	EventBus.damage_dealt.emit(target_id, spec.damage)


## FeedbackComponent가 있으면 그쪽으로, 없으면 target 직접 호출.
static func _play_target_flash(target: Node, color: Color) -> void:
	var feedback: Node = target.get_node_or_null("FeedbackComponent")
	if feedback != null and feedback.has_method("play_hit_flash"):
		feedback.play_hit_flash(color)
		return
	if target.has_method("play_hit_flash"):
		target.call("play_hit_flash", color)


## stats_data.enemy_type을 보고 파티클 카테고리 결정. 없으면 기본값.
static func _resolve_enemy_category(target: Node) -> StringName:
	var enemy_type: String = ""
	if "stats_data" in target:
		var stats: Variant = target.get("stats_data")
		if stats != null and "enemy_type" in stats:
			enemy_type = str(stats.enemy_type)
	return EffectsSystem.resolve_enemy_category(enemy_type)


## damage_dealt 페이로드용 ID. enemy_id 프로퍼티 우선, 없으면 get_entity_id(), 최후 0.
static func _resolve_target_id(target: Node) -> int:
	if "enemy_id" in target:
		return int(target.get("enemy_id"))
	if target.has_method("get_entity_id"):
		return int(target.call("get_entity_id"))
	return 0
