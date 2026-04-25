class_name DamageResolver
extends RefCounted

## hurtbox 접촉 시 데미지·이펙트·이벤트 분배를 전담하는 정적 헬퍼.
##
## Phase 4-0 #1 Step 6 (이펙트 EventBus 발행) + Effect Timeline Step 2 (선언적 시퀀스) 통합:
##   (a) base_enemy/base_boss/boss_weak_point 모두 resolve_hit / resolve_hit_weak_point 위임
##   (b) 타깃 차이(일반 적 vs 보스)는 컨트랙트 훅으로 ctx에 미리 계산해 timeline에 전달
##   (c) 5종 이펙트(flash/shake/hitstop/particle/screen_flash) 발행은 timeline 1회 호출로 단순화
##       — timeline_id 매핑은 _resolve_timeline_id, ctx 빌드는 _build_effects_context
##   (d) timeline cue dispatch가 EventBus.hit_flash_requested / hitstop_requested /
##       screen_flash_requested / screen_shake_requested 발행 — Step 6의 시그널 부활 유지
##
## 타깃 컨트랙트 (base_enemy / base_boss 가 구현):
##   apply_hit_damage(amount, is_weak_point) -> float (<= 0 이면 연출·숫자·이벤트 스킵)
##   spawn_damage_number(amount, is_finish, is_critical, attribute)
##   get_hit_flash_target() / get_hit_flash_duration() / get_hit_flash_base_color()
##   get_hit_particle_category() / get_hit_particle_offset()
##   get_damage_number_offset() / get_entity_id()
##   get_shake_preset_normal()

const _META_ATTACK_SPEC := "attack_spec"


## 일반 hurtbox 접촉. base_enemy/base_boss의 _on_hurtbox_area_entered에서 호출.
static func resolve_hit(target: Node, attacker_area: Area2D) -> void:
	_resolve_internal(target, attacker_area, false)


## 보스 약점 Area2D 접촉. boss_weak_point._on_area_entered에서 호출.
## take_damage에 weak_point 배수 적용 + shake/hitstop preset이 HEAVY/CRITICAL로 상향.
static func resolve_hit_weak_point(target: Node, attacker_area: Area2D) -> void:
	_resolve_internal(target, attacker_area, true)


static func _resolve_internal(target: Node, attacker_area: Area2D, is_weak_point: bool) -> void:
	if not is_instance_valid(target) or not is_instance_valid(attacker_area):
		return
	if not attacker_area.has_meta(_META_ATTACK_SPEC):
		return
	var spec: AttackSpec = attacker_area.get_meta(_META_ATTACK_SPEC) as AttackSpec
	if spec == null:
		return
	if not target.has_method("apply_hit_damage"):
		push_warning("DamageResolver: target %s missing apply_hit_damage hook" % target)
		return

	# 1) 데미지 적용 — 반환값 <= 0 이면 무적/사망으로 간주, 연출·이벤트는 스킵.
	var display_damage: float = target.apply_hit_damage(spec.damage, is_weak_point)
	if display_damage <= 0.0:
		# 무적 방어 피드백(β): "0" 데미지 숫자만 띄워 플레이어에게 "막힘" 전달.
		# 일반 미스(타깃이 이미 죽음 등)는 무음 유지.
		var is_invincible: bool = (
			target.has_method("is_hit_invincible") and target.call("is_hit_invincible")
		)
		if is_invincible and target.has_method("spawn_damage_number"):
			target.call("spawn_damage_number", 0.0, false, false, "")
		return

	# 2) 연출 5종(flash/shake/hitstop/particle/screen_flash) timeline 1회 발화
	_apply_effects(target, spec, is_weak_point)

	# 3) 데미지 숫자
	if target.has_method("spawn_damage_number"):
		target.call(
			"spawn_damage_number", display_damage, spec.is_finish, is_weak_point, spec.attribute
		)

	# 4) damage_dealt 이벤트 전파
	var target_id: int = 0
	if target.has_method("get_entity_id"):
		target_id = int(target.call("get_entity_id"))
	EventBus.damage_dealt.emit(target_id, display_damage)


static func _apply_effects(target: Node, spec: AttackSpec, is_weak_point: bool) -> void:
	var timeline_id: StringName = _resolve_timeline_id(spec, is_weak_point)
	var ctx: Dictionary = _build_effects_context(target, spec)
	EffectsSystem.request_timeline_by_id(timeline_id, ctx)


static func _resolve_timeline_id(spec: AttackSpec, is_weak_point: bool) -> StringName:
	if spec.is_finish:
		match spec.attribute:
			"light":
				return &"finish_light"
			"shadow":
				return &"finish_shadow"
			"hybrid":
				return &"finish_hybrid"
			_:
				return &"finish_neutral"
	if is_weak_point:
		return &"hit_critical"
	return &"hit_normal"


static func _build_effects_context(target: Node, spec: AttackSpec) -> Dictionary:
	var ctx: Dictionary = {}
	ctx[&"finish_attribute"] = spec.attribute
	ctx[&"is_finish"] = spec.is_finish

	# flash target — get_hit_flash_target() 우선, 없으면 AnimatedSprite2D fallback
	var flash_target: CanvasItem = null
	if target.has_method("get_hit_flash_target"):
		flash_target = target.call("get_hit_flash_target") as CanvasItem
	if flash_target == null:
		flash_target = target.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if flash_target != null:
		ctx[&"target"] = flash_target

	# hit_flash base color/duration — cue.flash_color/duration이 비어있을 때 fallback
	if target.has_method("get_hit_flash_base_color"):
		ctx[&"flash_color"] = target.call("get_hit_flash_base_color")
	if target.has_method("get_hit_flash_duration"):
		ctx[&"flash_duration"] = target.call("get_hit_flash_duration")

	# 파티클: world_pos = target.global_position + get_hit_particle_offset()
	if target is Node2D:
		var offset: Vector2 = Vector2.ZERO
		if target.has_method("get_hit_particle_offset"):
			offset = target.call("get_hit_particle_offset")
		ctx[&"world_pos"] = (target as Node2D).global_position + offset

	if target.has_method("get_hit_particle_category"):
		ctx[&"particle_category"] = target.call("get_hit_particle_category")

	# 일반 hit shake preset (보스=MEDIUM, 일반 적=LIGHT) — hit_normal.tres가 from_context로 수신
	if target.has_method("get_shake_preset_normal"):
		ctx[&"shake_preset"] = String(target.call("get_shake_preset_normal"))
	else:
		ctx[&"shake_preset"] = String(EffectsSystem.PRESET_LIGHT)

	return ctx
