extends Node

## Phase 3-7 Pass 1/3/4 — 이펙트 시연용 디버그 키.
## OS.is_debug_build() 시에만 활성화. F4 + F6~F9 + F12.
## EffectsSystem Autoload의 자식으로 등록되거나 별도 시연 씬에서 직접 add_child.
## 주의: F10/F11은 InventorySystem 디버그가 선점, F5는 GrowthSystem.

const KEY_TIMELINE_TEST: Key = KEY_F2
const KEY_DISSOLVE: Key = KEY_F3
const KEY_DUSK_WARNING: Key = KEY_F4
const KEY_SHAKE: Key = KEY_F6
const KEY_HIT_FLASH: Key = KEY_F7
const KEY_HITSTOP: Key = KEY_F8
const KEY_SCREEN_FLASH: Key = KEY_F9
const KEY_TIME_STOP: Key = KEY_F12

var _dissolve_covered: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_input(false)
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event: InputEventKey = event
	match key_event.keycode:
		KEY_TIMELINE_TEST:
			_test_timeline_pipeline()
			get_viewport().set_input_as_handled()
		KEY_DISSOLVE:
			_dissolve_covered = not _dissolve_covered
			EffectsSystem.request_dissolve(0.3, _dissolve_covered)
			print("[EffectsDebug] dissolve cover=%s" % _dissolve_covered)
			get_viewport().set_input_as_handled()
		KEY_DUSK_WARNING:
			var next_dist: int = EffectsSystem.debug_cycle_dusk_distance()
			print("[EffectsDebug] dusk warning distance → %d" % next_dist)
			get_viewport().set_input_as_handled()
		KEY_SHAKE:
			EffectsSystem.request_shake(EffectsSystem.PRESET_HEAVY)
			print("[EffectsDebug] shake heavy")
			get_viewport().set_input_as_handled()
		KEY_HIT_FLASH:
			_flash_nearest_enemy()
			get_viewport().set_input_as_handled()
		KEY_HITSTOP:
			EffectsSystem.request_hitstop(EffectsSystem.PRESET_FINISH)
			print("[EffectsDebug] hitstop finish (0.17s)")
			get_viewport().set_input_as_handled()
		KEY_SCREEN_FLASH:
			EffectsSystem.request_screen_flash(Color(1.0, 1.0, 1.0, 0.5), 0.1)
			print("[EffectsDebug] screen flash")
			get_viewport().set_input_as_handled()
		KEY_TIME_STOP:
			EffectsSystem.debug_toggle_time_stop()
			print("[EffectsDebug] time stop toggle")
			get_viewport().set_input_as_handled()


## Step 1 scaffolding 검증: 동적 합성 timeline으로 end-to-end 파이프라인 실행.
## shake(0s) + screen_flash(0.05s) + hitstop(0.08s) 3 cue — 기존 Layer 2 API 단순 연쇄 확인.
func _test_timeline_pipeline() -> void:
	var timeline := EffectTimeline.new()
	timeline.display_name = "DebugSynthetic"
	timeline.time_policy = "ignore"
	timeline.expected_duration = 0.2

	var shake_cue := EffectCue.new()
	shake_cue.offset_sec = 0.0
	shake_cue.cue_type = "shake"
	shake_cue.shake_preset = "medium"

	var flash_cue := EffectCue.new()
	flash_cue.offset_sec = 0.05
	flash_cue.cue_type = "screen_flash"
	flash_cue.screen_flash_color = Color(0.4, 0.9, 1.0, 0.35)
	flash_cue.screen_flash_duration = 0.12

	var hitstop_cue := EffectCue.new()
	hitstop_cue.offset_sec = 0.08
	hitstop_cue.cue_type = "hitstop"
	hitstop_cue.hitstop_preset = "hit"

	timeline.cues = [shake_cue, flash_cue, hitstop_cue]
	var handle: EffectsTimelinePlayer = EffectsSystem.request_timeline(timeline, {})
	print(
		(
			"[EffectsDebug] timeline test fired → %s (handle=%s)"
			% [timeline.display_name, "ok" if handle else "null"]
		)
	)


func _flash_nearest_enemy() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		print("[EffectsDebug] flash: 적 없음")
		return
	var target_node: Node2D = enemies[0] as Node2D
	if target_node == null:
		return
	var sprite: CanvasItem = target_node.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if sprite == null:
		return
	EffectsSystem.request_hit_flash(sprite, Color.WHITE, 0.15)
	print("[EffectsDebug] hit_flash → %s" % target_node.name)
