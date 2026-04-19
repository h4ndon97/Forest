extends Node

## Phase 3-7 Pass 1 — 이펙트 시연용 디버그 키.
## OS.is_debug_build() 시에만 활성화. F6~F9.
## EffectsSystem Autoload의 자식으로 등록되거나 별도 시연 씬에서 직접 add_child.
## InputMap에 등록된 키와 충돌하지 않도록 F6~F9 사용 (현재 미점유).

const KEY_SHAKE: Key = KEY_F6
const KEY_HIT_FLASH: Key = KEY_F7
const KEY_HITSTOP: Key = KEY_F8
const KEY_SCREEN_FLASH: Key = KEY_F9


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
