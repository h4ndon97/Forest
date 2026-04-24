class_name DamageResolver
extends RefCounted

## hurtbox 접촉 시 데미지·이펙트·이벤트 분배를 전담하는 정적 헬퍼.
##
## Phase 4-0 #1 Step 6 전환 완료:
##   (a) EventBus.hit_flash_requested / hitstop_requested emit — EffectsSystem이 구독
##   (b) base_enemy._on_hurtbox_area_entered / base_boss._on_hurtbox_area_entered / boss_weak_point
##       모두 resolve_hit / resolve_hit_weak_point 위임
##   (c) 타깃 차이(일반 적 vs 보스, 플래시 duration/color, 파티클 카테고리/오프셋,
##       데미지 넘버 오프셋, shake preset 기본값)는 타깃이 제공하는 컨트랙트 훅으로 해결
##   (d) screen_flash_requested emit은 #3 속성 피니시에서 연결 예정 — 본 Step은 TODO만 남김
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

	# 1) 데미지 적용 — 반환값 <= 0 이면 무적/사망으로 간주, 연출·숫자·이벤트 전부 스킵.
	var display_damage: float = target.apply_hit_damage(spec.damage, is_weak_point)
	if display_damage <= 0.0:
		return

	# 2) 연출 5종 (플래시/쉐이크/힛스톱/파티클) 발행
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
	# 플래시 — EventBus.hit_flash_requested emit (EffectsSystem._on_hit_flash_requested 수신)
	var flash_target: CanvasItem = null
	if target.has_method("get_hit_flash_target"):
		flash_target = target.call("get_hit_flash_target") as CanvasItem
	else:
		flash_target = target.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if flash_target != null:
		var flash_color: Color = _resolve_flash_color(target, spec)
		var flash_duration: float = _resolve_flash_duration(target)
		EventBus.hit_flash_requested.emit(flash_target, flash_color, flash_duration)

	# 쉐이크 — screen_shake_requested는 Pass 1에서 이미 연결. EffectsSystem.request_shake 경유 유지.
	EffectsSystem.request_shake(_resolve_shake_preset(target, spec, is_weak_point))

	# 힛스톱 — preset을 duration으로 변환한 뒤 EventBus.hitstop_requested emit
	var hitstop_preset: StringName = _resolve_hitstop_preset(spec.is_finish, is_weak_point)
	var hitstop_duration: float = EffectsSystem.resolve_hitstop_preset_duration(hitstop_preset)
	EventBus.hitstop_requested.emit(hitstop_duration, -1.0)

	# 파티클 — 시그널 미정의. 현 상태 EffectsSystem 직접 호출 유지.
	if target is Node2D:
		var offset: Vector2 = Vector2.ZERO
		if target.has_method("get_hit_particle_offset"):
			offset = target.call("get_hit_particle_offset")
		var world_pos: Vector2 = (target as Node2D).global_position + offset
		var category: StringName = EffectsSystem.CATEGORY_SHADOW
		if target.has_method("get_hit_particle_category"):
			category = target.call("get_hit_particle_category")
		EffectsSystem.request_hit_particle(world_pos, category, spec.is_finish, spec.attribute)

	# TODO(Phase 4-0 #3): spec.attribute == "light" 피니시 시
	#   EventBus.screen_flash_requested.emit(light_flash_color, duration)


static func _resolve_flash_color(target: Node, spec: AttackSpec) -> Color:
	if spec.is_finish and spec.attribute != "none" and spec.attribute != "":
		return EffectsSystem.get_finish_color(spec.attribute)
	if target.has_method("get_hit_flash_base_color"):
		return target.call("get_hit_flash_base_color")
	return EffectsSystem.get_config().default_flash_color


static func _resolve_flash_duration(target: Node) -> float:
	if target.has_method("get_hit_flash_duration"):
		return float(target.call("get_hit_flash_duration"))
	return EffectsSystem.get_config().default_flash_duration


static func _resolve_shake_preset(
	target: Node, spec: AttackSpec, is_weak_point: bool
) -> StringName:
	if spec.is_finish:
		return EffectsSystem.PRESET_FINISH
	if is_weak_point:
		return EffectsSystem.PRESET_HEAVY
	if target.has_method("get_shake_preset_normal"):
		return target.call("get_shake_preset_normal")
	return EffectsSystem.PRESET_LIGHT


static func _resolve_hitstop_preset(is_finish: bool, is_weak_point: bool) -> StringName:
	if is_finish:
		return EffectsSystem.PRESET_FINISH
	if is_weak_point:
		return EffectsSystem.PRESET_CRITICAL
	return EffectsSystem.PRESET_HIT
