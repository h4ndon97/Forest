class_name EffectsTimelineDispatch
extends RefCounted

## cue 1건을 EffectsSystem Layer 2 API로 분기하는 정적 헬퍼.
## Player가 타이머 도달 시 `dispatch(cue, ctx)`를 호출한다.
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §5.

const CTX_TARGET := &"target"
const CTX_WORLD_POS := &"world_pos"
const CTX_AFTERIMAGE_SOURCE := &"afterimage_source"
const CTX_FINISH_ATTRIBUTE := &"finish_attribute"
const CTX_IS_FINISH := &"is_finish"
const CTX_EXTRA := &"extra"


static func dispatch(cue: EffectCue, ctx: Dictionary) -> void:
	if cue == null:
		return
	match cue.cue_type:
		"hit_flash":
			_fire_hit_flash(cue, ctx)
		"shake":
			_fire_shake(cue)
		"hitstop":
			_fire_hitstop(cue)
		"screen_flash":
			_fire_screen_flash(cue)
		"afterimage":
			_fire_afterimage(cue, ctx)
		"hit_particle":
			_fire_hit_particle(cue, ctx)
		"event_emit":
			_fire_event_emit(cue)
		_:
			push_warning("EffectsTimelineDispatch: unknown cue_type '%s'" % cue.cue_type)


static func _fire_hit_flash(cue: EffectCue, ctx: Dictionary) -> void:
	var target: CanvasItem = _resolve_flash_target(cue, ctx)
	if target == null:
		return
	var color_to_use: Color = cue.flash_color
	if cue.flash_use_finish_color:
		var attr: String = ctx.get(CTX_FINISH_ATTRIBUTE, "")
		if attr != "":
			color_to_use = EffectsSystem.get_finish_color(attr)
	EffectsSystem.request_hit_flash(target, color_to_use, cue.flash_duration)


static func _fire_shake(cue: EffectCue) -> void:
	if cue.shake_preset == "custom" and cue.shake_trauma_override > 0.0:
		EffectsSystem.request_shake_amount(cue.shake_trauma_override)
		return
	EffectsSystem.request_shake(StringName(cue.shake_preset))


static func _fire_hitstop(cue: EffectCue) -> void:
	if cue.hitstop_preset == "custom" and cue.hitstop_duration_override > 0.0:
		EffectsSystem.request_hitstop_duration(
			cue.hitstop_duration_override, cue.hitstop_scale_override
		)
		return
	EffectsSystem.request_hitstop(StringName(cue.hitstop_preset))


static func _fire_screen_flash(cue: EffectCue) -> void:
	EffectsSystem.request_screen_flash(cue.screen_flash_color, cue.screen_flash_duration)


static func _fire_afterimage(cue: EffectCue, ctx: Dictionary) -> void:
	var source: Node2D = ctx.get(CTX_AFTERIMAGE_SOURCE) as Node2D
	if source == null:
		push_warning("EffectsTimelineDispatch: afterimage cue requires ctx.afterimage_source")
		return
	EffectsSystem.request_afterimage(
		source, cue.afterimage_count, cue.afterimage_interval, cue.afterimage_fade
	)


static func _fire_hit_particle(cue: EffectCue, ctx: Dictionary) -> void:
	var world_pos: Vector2 = ctx.get(CTX_WORLD_POS, Vector2.ZERO)
	var category: StringName = _resolve_particle_category(cue, ctx)
	var attr: String = cue.particle_attribute_override
	if attr == "":
		attr = ctx.get(CTX_FINISH_ATTRIBUTE, "")
	EffectsSystem.request_hit_particle(world_pos, category, cue.particle_is_finish, attr)


static func _fire_event_emit(cue: EffectCue) -> void:
	if cue.event_name == &"":
		return
	if not EventBus.has_signal(cue.event_name):
		push_warning("EffectsTimelineDispatch: EventBus signal '%s' not found" % cue.event_name)
		return
	EventBus.emit_signal(cue.event_name, cue.event_args)


static func _resolve_flash_target(cue: EffectCue, ctx: Dictionary) -> CanvasItem:
	if cue.flash_target_path == "":
		return ctx.get(CTX_TARGET) as CanvasItem
	# 중첩 키 해석: "context.extra.finish_target" 같은 경로는 Step 2+ 필요 시 확장.
	# Step 1 범위: 단순 키만 ctx에서 직접 조회.
	return ctx.get(StringName(cue.flash_target_path)) as CanvasItem


static func _resolve_particle_category(cue: EffectCue, ctx: Dictionary) -> StringName:
	if cue.particle_category == "resolve_from_context":
		var cat: Variant = ctx.get(&"particle_category", EffectsSystem.CATEGORY_SHADOW)
		return cat as StringName
	return StringName(cue.particle_category)
