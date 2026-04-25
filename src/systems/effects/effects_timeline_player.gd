class_name EffectsTimelinePlayer
extends Node

## 타임라인 1건의 실행 인스턴스. EffectsSystem.request_timeline이 add_child로 붙인다.
## cue offset 스케줄링 → EffectsTimelineDispatch로 Layer 2 API 호출 → 완료 후 queue_free.
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §5.

const DispatchScript = preload("res://src/systems/effects/effects_timeline_dispatch.gd")

## 모든 cue 완료 후 자가 해제까지의 여유(초).
const CLEANUP_GRACE := 1.0

var _timeline: EffectTimeline
var _context: Dictionary
## 미발화 SceneTreeTimer 참조(취소용). 발화한 cue는 제거되지 않음(위임 완료).
var _pending_timers: Array[SceneTreeTimer] = []


func setup(timeline: EffectTimeline, ctx: Dictionary) -> void:
	_timeline = timeline
	_context = ctx
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if _timeline == null:
		queue_free()
		return
	# PauseMenu 중 재생 금지 (안전 기본값).
	if get_tree().paused and not _timeline.allow_during_pause:
		queue_free()
		return
	_schedule_cues()


## 미발화 cue 발화를 모두 취소. 이미 발화된 cue는 Layer 2에 위임되어 되돌릴 수 없음.
func cancel() -> void:
	_pending_timers.clear()
	queue_free()


# === 내부 ===


func _schedule_cues() -> void:
	var ignore_ts: bool = _timeline.time_policy == "ignore"
	var sorted_cues: Array = _timeline.cues.duplicate()
	sorted_cues.sort_custom(_cue_order)

	var max_offset: float = 0.0
	var tree: SceneTree = get_tree()
	for cue_any in sorted_cues:
		var cue: EffectCue = cue_any as EffectCue
		if cue == null:
			continue
		max_offset = maxf(max_offset, cue.offset_sec)
		if cue.offset_sec <= 0.0:
			_fire_cue(cue)
		else:
			var timer: SceneTreeTimer = tree.create_timer(cue.offset_sec, true, false, ignore_ts)
			timer.timeout.connect(_fire_cue.bind(cue))
			_pending_timers.append(timer)

	var cleanup_delay: float = max_offset + CLEANUP_GRACE
	var cleanup_timer: SceneTreeTimer = tree.create_timer(cleanup_delay, true, false, ignore_ts)
	cleanup_timer.timeout.connect(queue_free)


static func _cue_order(a: EffectCue, b: EffectCue) -> bool:
	return a.offset_sec < b.offset_sec


func _fire_cue(cue: EffectCue) -> void:
	if cue == null:
		return
	if not _check_condition(cue):
		return
	if cue.probability < 1.0 and randf() > cue.probability:
		return
	DispatchScript.dispatch(cue, _context)


## Step 1 범위: 단순 키 체크만 지원.
##   빈 문자열 → 무조건 true
##   "is_finish" → ctx.is_finish
##   "attribute==light" → ctx.finish_attribute == "light"
## 복잡한 표현식은 Step 2+ 필요 시 확장.
func _check_condition(cue: EffectCue) -> bool:
	if cue.condition.is_empty():
		return true
	if cue.condition == "is_finish":
		return bool(_context.get(DispatchScript.CTX_IS_FINISH, false))
	if cue.condition.begins_with("attribute=="):
		var expected: String = cue.condition.substr("attribute==".length())
		return str(_context.get(DispatchScript.CTX_FINISH_ATTRIBUTE, "")) == expected
	push_warning("EffectsTimelinePlayer: unknown condition '%s'" % cue.condition)
	return false
