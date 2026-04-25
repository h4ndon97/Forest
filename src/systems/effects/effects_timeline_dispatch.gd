class_name EffectsTimelineDispatch
extends RefCounted

## cue 1건을 EventBus emit / Layer 2 API로 분기하는 정적 헬퍼.
## Player가 타이머 도달 시 `dispatch(cue, ctx)`를 호출한다.
## 시그널 정합 정책: hit_flash/hitstop/screen_flash/shake는 EventBus 경유로 발행해
## Phase 4-0 #1 Step 6에서 부활시킨 시그널 3종이 timeline 전환 후에도 살아있도록 보장.
## afterimage/hit_particle은 시그널 미정의로 EffectsSystem 직접 호출.
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §5.

const CTX_TARGET := &"target"
const CTX_WORLD_POS := &"world_pos"
const CTX_AFTERIMAGE_SOURCE := &"afterimage_source"
const CTX_FINISH_ATTRIBUTE := &"finish_attribute"
const CTX_IS_FINISH := &"is_finish"
const CTX_EXTRA := &"extra"
## cue 값이 비어있을 때 fallback / "from_context" 옵션 사용.
const CTX_FLASH_COLOR := &"flash_color"
const CTX_FLASH_DURATION := &"flash_duration"
const CTX_PARTICLE_CATEGORY := &"particle_category"
const CTX_SHAKE_PRESET := &"shake_preset"


static func dispatch(cue: EffectCue, ctx: Dictionary) -> void:
	if cue == null:
		return
	match cue.cue_type:
		"hit_flash":
			_fire_hit_flash(cue, ctx)
		"shake":
			_fire_shake(cue, ctx)
		"hitstop":
			_fire_hitstop(cue)
		"screen_flash":
			_fire_screen_flash(cue, ctx)
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
	elif color_to_use.a == 0.0:
		color_to_use = ctx.get(CTX_FLASH_COLOR, EffectsSystem.get_config().default_flash_color)

	var dur: float = cue.flash_duration
	if dur < 0.0:
		dur = ctx.get(CTX_FLASH_DURATION, EffectsSystem.get_config().default_flash_duration)

	EventBus.hit_flash_requested.emit(target, color_to_use, dur)


static func _fire_shake(cue: EffectCue, ctx: Dictionary) -> void:
	# EffectsSystem.request_shake* 내부에서 EventBus.screen_shake_requested.emit — 시그널 보존.
	if cue.shake_preset == "from_context":
		var ctx_preset: String = ctx.get(CTX_SHAKE_PRESET, "")
		if ctx_preset != "":
			EffectsSystem.request_shake(StringName(ctx_preset))
			return
		# 폴백: ctx에 없으면 medium.
		EffectsSystem.request_shake(EffectsSystem.PRESET_MEDIUM)
		return
	if cue.shake_preset == "custom" and cue.shake_trauma_override > 0.0:
		EffectsSystem.request_shake_amount(cue.shake_trauma_override)
		return
	EffectsSystem.request_shake(StringName(cue.shake_preset))


static func _fire_hitstop(cue: EffectCue) -> void:
	var dur: float
	var scale_override: float
	if cue.hitstop_preset == "custom" and cue.hitstop_duration_override > 0.0:
		dur = cue.hitstop_duration_override
		scale_override = cue.hitstop_scale_override
	else:
		dur = EffectsSystem.resolve_hitstop_preset_duration(StringName(cue.hitstop_preset))
		scale_override = -1.0
	EventBus.hitstop_requested.emit(dur, scale_override)


static func _fire_screen_flash(cue: EffectCue, ctx: Dictionary) -> void:
	var color: Color = cue.screen_flash_color
	if cue.screen_flash_use_finish_color:
		var attr: String = ctx.get(CTX_FINISH_ATTRIBUTE, "")
		if attr != "":
			color = EffectsSystem.get_finish_color(attr)
	EventBus.screen_flash_requested.emit(color, cue.screen_flash_duration)


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
	return ctx.get(StringName(cue.flash_target_path)) as CanvasItem


static func _resolve_particle_category(cue: EffectCue, ctx: Dictionary) -> StringName:
	if cue.particle_category == "resolve_from_context":
		var cat: Variant = ctx.get(CTX_PARTICLE_CATEGORY, EffectsSystem.CATEGORY_SHADOW)
		return cat as StringName
	return StringName(cue.particle_category)
