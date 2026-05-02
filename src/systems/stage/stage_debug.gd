extends Node

## 디버그 빌드 한정 — F2로 토글되는 스테이지 점프 오버레이.
## 등록된 모든 스테이지 일람 + ↑/↓ 선택 + Enter 점프 + Esc/F2 닫기.
## `transition_to_stage(.., {"bypass_lock": true})` 경유로 PURIFY/ENVIRONMENT 잠금도 우회.
## ABILITY 잠금은 `_DEBUG_AUTO_UNLOCK_ALL=true`로 이미 해금되어 있음.
## F1은 KeybindHud(인게임 키 할당 확인) 점유.

const KEY_TOGGLE: Key = KEY_F2

var _overlay: CanvasLayer
var _label: RichTextLabel
var _stage_ids: Array = []
var _selected_index: int = 0


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_input(false)
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()


func _unhandled_input(event: InputEvent) -> void:
	# 디버그 빌드 한정 점프 핫키 — 가변 룸/카메라/회귀 테스트용 (StageSystem에서 이주).
	# 일반 점프는 F2 본 오버레이로 통일.
	if event.is_action_pressed("debug_jump_start_village"):
		EventBus.stage_transition_requested.emit("start_village", "checkpoint", {})
		return
	if event.is_action_pressed("debug_jump_boss_1b"):
		EventBus.stage_transition_requested.emit("stage_1_b", "checkpoint", {})
		return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event: InputEventKey = event
	var key: int = key_event.keycode

	if key == KEY_TOGGLE:
		_toggle_overlay()
		get_viewport().set_input_as_handled()
		return

	if _overlay == null or not _overlay.visible:
		return

	match key:
		KEY_UP:
			_move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_jump_to_selected()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_set_overlay_visible(false)
			get_viewport().set_input_as_handled()


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	_overlay.visible = false
	add_child(_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(margin)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_label)


func _toggle_overlay() -> void:
	if _overlay == null:
		return
	_set_overlay_visible(not _overlay.visible)


func _set_overlay_visible(make_visible: bool) -> void:
	if _overlay == null:
		return
	if make_visible:
		_refresh_stage_list()
		_render()
	_overlay.visible = make_visible
	get_tree().paused = make_visible


func _refresh_stage_list() -> void:
	_stage_ids = StageSystem.get_all_stage_ids()
	_stage_ids.sort()
	if _stage_ids.is_empty():
		_selected_index = 0
	else:
		_selected_index = clampi(_selected_index, 0, _stage_ids.size() - 1)


func _render() -> void:
	if _label == null:
		return
	var lines := PackedStringArray()
	lines.append("[b]🐛 Stage Debug — F2/Esc to close[/b]")
	lines.append("")
	for i in _stage_ids.size():
		var stage_id: String = _stage_ids[i]
		var data: StageData = StageSystem.get_stage_data(stage_id)
		var display_name: String = data.display_name if data else stage_id
		var marker := "[color=#ffd966]> [/color]" if i == _selected_index else "  "
		var line: String = "%s%s [color=#888888][%s][/color]" % [marker, display_name, stage_id]
		if i == _selected_index:
			line = "[bgcolor=#332f1a]" + line + "[/bgcolor]"
		lines.append(line)
	lines.append("")
	lines.append("[i]↑↓ select | Enter to jump | Esc to close[/i]")
	_label.text = "\n".join(lines)


func _move_selection(delta: int) -> void:
	if _stage_ids.is_empty():
		return
	var size: int = _stage_ids.size()
	_selected_index = (_selected_index + delta + size) % size
	_render()


func _jump_to_selected() -> void:
	if _selected_index < 0 or _selected_index >= _stage_ids.size():
		return
	var stage_id: String = _stage_ids[_selected_index]
	_set_overlay_visible(false)
	EventBus.stage_transition_requested.emit(stage_id, "checkpoint", {"bypass_lock": true})
	print("[StageDebug] jumped to ", stage_id)
