extends Node

## Phase 3-7 Pass 1/3/4 — 이펙트 시연용 디버그 키.
## OS.is_debug_build() 시에만 활성화. F3~F4 + F6~F9 + F12.
## EffectsSystem Autoload의 자식으로 등록되거나 별도 시연 씬에서 직접 add_child.
## 주의: F1=KeybindHud / F2=StageDebug / F5=GrowthSystem / F10·F11=InventorySystem 점유.

const KEY_DISSOLVE: Key = KEY_F3
const KEY_DUSK_WARNING: Key = KEY_F4
const KEY_SHAKE: Key = KEY_F6
const KEY_HIT_FLASH: Key = KEY_F7
const KEY_HITSTOP: Key = KEY_F8
const KEY_SCREEN_FLASH: Key = KEY_F9
const KEY_TIME_STOP: Key = KEY_F12


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
		KEY_DISSOLVE:
			EffectsSystem.request_dissolve_flash()
			print("[EffectsDebug] dissolve flash (cover→reveal 1회)")
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
