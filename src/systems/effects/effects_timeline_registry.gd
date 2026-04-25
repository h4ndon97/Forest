class_name EffectsTimelineRegistry
extends RefCounted

## data/effects/timelines/*.tres를 런타임 스캔 → id(StringName) → EffectTimeline 매핑.
## EffectsSystem._ready()가 인스턴스화해 보유. Autoload 아님.
## id = 파일 basename (확장자 제거). 예: "finish_light.tres" → &"finish_light".
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §4.1, §8.

const TIMELINE_DIR := "res://data/effects/timelines/"

var _timelines: Dictionary = {}  # StringName → EffectTimeline


func load_all() -> void:
	_timelines.clear()
	var dir := DirAccess.open(TIMELINE_DIR)
	if dir == null:
		# 폴더 자체 없으면 무시(Step 1 scaffolding 시점엔 정상).
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".tres"):
			var path := TIMELINE_DIR + entry
			var res: Resource = load(path)
			if res is EffectTimeline:
				var id := StringName(entry.get_basename())
				_timelines[id] = res
			else:
				push_warning("EffectsTimelineRegistry: %s is not EffectTimeline, skipped" % path)
		entry = dir.get_next()
	dir.list_dir_end()
	print("[EffectsTimelineRegistry] Loaded %d timelines" % _timelines.size())


func get_timeline(id: StringName) -> EffectTimeline:
	return _timelines.get(id)


func has_timeline(id: StringName) -> bool:
	return _timelines.has(id)


func get_all_ids() -> Array:
	return _timelines.keys()
