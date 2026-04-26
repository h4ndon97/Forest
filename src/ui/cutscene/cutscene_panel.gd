class_name CutscenePanel
extends CanvasLayer

## REC-FX-006 — 컷신 (정지 일러스트 + 텍스트박스).
## OverlaySystem이 1회용 인스턴스로 생성/추가/start. 종료 시 self queue_free.
## DialogueBox와 별개 — 더 무거운 연출 (배경 dim + 일러스트 + 페이드 + typewriter + 스킵).
## 시네마틱 바는 OverlaySystem.play_cinematic_bars()로 위 layer에서 별도 그려짐.

const LAYER_INDEX: int = 99  # OverlaySystem(100)보다 아래 → 바가 위에 떨어짐
const DIM_ALPHA: float = 0.85
const ILLUSTRATION_SIZE: Vector2 = Vector2(320, 180)
const TEXTBOX_HEIGHT: int = 64
const TEXTBOX_MARGIN: int = 24
const FONT_SIZE_LINE: int = 11
const FONT_SIZE_SPEAKER: int = 10
const FONT_SIZE_HINT: int = 8
const TYPEWRITER_CPS: float = 32.0  # characters per second
const SKIP_HINT: String = "[ESC] 건너뛰기"
const ADVANCE_HINT: String = "[F] 계속"

var _data: CutsceneData = null
var _panel_index: int = 0
var _line_index: int = 0
var _is_armed: bool = false
var _is_typing: bool = false
var _is_finished: bool = false
var _player: Node = null
var _illustration: TextureRect = null
var _placeholder: ColorRect = null
var _textbox_panel: Panel = null
var _line_label: RichTextLabel = null
var _speaker_label: Label = null
var _hint_label: Label = null
var _dim_rect: ColorRect = null
var _content_root: Control = null
var _typing_tween: Tween = null
var _fade_tween: Tween = null
var _auto_timer: SceneTreeTimer = null


func start(data: CutsceneData) -> void:
	if data == null or data.panels.is_empty():
		queue_free()
		return
	_data = data
	_panel_index = 0
	_line_index = 0
	layer = LAYER_INDEX
	_build_ui()
	_lock_player_input()
	if _data.cinematic_bar_thickness > 0.0 and OverlaySystem != null:
		OverlaySystem.play_cinematic_bars(0.30, 9999.0, _data.cinematic_bar_thickness)
	if _data.pause_time_during and Engine.has_singleton("TimeSystem"):
		pass  # TimeSystem 정지 hook은 추후 (현 단계에선 false 기본)
	EventBus.cutscene_started.emit(_data.cutscene_id)
	_show_panel(0)
	call_deferred("_arm")


func _arm() -> void:
	_is_armed = true


func _input(event: InputEvent) -> void:
	if not _is_armed or _is_finished:
		return
	if event.is_action_pressed("ui_cancel") and _data.skippable:
		_finish()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _is_typing:
		_finish_typing()
		return
	var current_panel: CutscenePanelData = _data.panels[_panel_index]
	if _line_index + 1 < current_panel.lines.size():
		_line_index += 1
		_show_line()
		return
	if _panel_index + 1 < _data.panels.size():
		_transition_to_next_panel()
		return
	_finish()


func _transition_to_next_panel() -> void:
	_panel_index += 1
	_line_index = 0
	var prev_panel: CutscenePanelData = _data.panels[_panel_index - 1]
	var next_panel: CutscenePanelData = _data.panels[_panel_index]
	_kill_fade()
	_fade_tween = create_tween()
	_fade_tween.set_ignore_time_scale(true)
	_fade_tween.tween_property(_content_root, "modulate:a", 0.0, prev_panel.fade_out)
	_fade_tween.tween_callback(_apply_panel_assets.bind(next_panel))
	_fade_tween.tween_property(_content_root, "modulate:a", 1.0, next_panel.fade_in)
	_fade_tween.tween_callback(_show_line)


func _show_panel(index: int) -> void:
	var panel_data: CutscenePanelData = _data.panels[index]
	_apply_panel_assets(panel_data)
	_content_root.modulate.a = 0.0
	_kill_fade()
	_fade_tween = create_tween()
	_fade_tween.set_ignore_time_scale(true)
	_fade_tween.tween_property(_content_root, "modulate:a", 1.0, panel_data.fade_in)
	_fade_tween.tween_callback(_show_line)


func _apply_panel_assets(panel_data: CutscenePanelData) -> void:
	var tex: Texture2D = null
	if not panel_data.image_path.is_empty() and ResourceLoader.exists(panel_data.image_path):
		tex = load(panel_data.image_path) as Texture2D
	if tex != null:
		_illustration.texture = tex
		_illustration.visible = true
		_placeholder.visible = false
	else:
		_illustration.texture = null
		_illustration.visible = false
		_placeholder.color = panel_data.placeholder_tint
		_placeholder.visible = true
	if panel_data.speaker.is_empty():
		_speaker_label.visible = false
	else:
		_speaker_label.text = panel_data.speaker
		_speaker_label.visible = true


func _show_line() -> void:
	var panel_data: CutscenePanelData = _data.panels[_panel_index]
	if _line_index >= panel_data.lines.size():
		return
	var line: String = panel_data.lines[_line_index]
	_line_label.text = line
	_line_label.visible_ratio = 0.0
	_is_typing = true
	_kill_typing()
	var duration: float = max(0.05, float(line.length()) / TYPEWRITER_CPS)
	_typing_tween = create_tween()
	_typing_tween.set_ignore_time_scale(true)
	_typing_tween.tween_property(_line_label, "visible_ratio", 1.0, duration)
	_typing_tween.tween_callback(_on_typing_finished)


func _finish_typing() -> void:
	_kill_typing()
	_line_label.visible_ratio = 1.0
	_is_typing = false


func _on_typing_finished() -> void:
	_is_typing = false
	var panel_data: CutscenePanelData = _data.panels[_panel_index]
	var is_last_line: bool = _line_index + 1 >= panel_data.lines.size()
	if is_last_line and panel_data.auto_advance_hold > 0.0:
		_auto_timer = get_tree().create_timer(panel_data.auto_advance_hold, true, false, true)
		_auto_timer.timeout.connect(_advance)


func _finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	_kill_typing()
	_kill_fade()
	_restore_player_input()
	if OverlaySystem != null and _data != null and _data.cinematic_bar_thickness > 0.0:
		OverlaySystem.play_cinematic_bars(0.30, 0.0, _data.cinematic_bar_thickness)
	var cutscene_id: String = _data.cutscene_id if _data != null else ""
	EventBus.cutscene_finished.emit(cutscene_id)
	queue_free()


func _kill_typing() -> void:
	if _typing_tween != null and _typing_tween.is_valid():
		_typing_tween.kill()


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()


func _lock_player_input() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	_player.set_physics_process(false)
	if _player is CharacterBody2D:
		(_player as CharacterBody2D).velocity = Vector2.ZERO


func _restore_player_input() -> void:
	if _player != null and is_instance_valid(_player):
		_player.set_physics_process(true)


func _build_ui() -> void:
	_dim_rect = ColorRect.new()
	_dim_rect.name = "Dim"
	_dim_rect.color = Color(0.0, 0.0, 0.0, DIM_ALPHA)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim_rect)

	_content_root = Control.new()
	_content_root.name = "Content"
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content_root)

	_build_illustration()
	_build_textbox()
	_build_hint()


func _build_illustration() -> void:
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var top_offset: float = (viewport.y - ILLUSTRATION_SIZE.y - TEXTBOX_HEIGHT - TEXTBOX_MARGIN) * 0.5
	var left_offset: float = (viewport.x - ILLUSTRATION_SIZE.x) * 0.5

	_placeholder = ColorRect.new()
	_placeholder.name = "Placeholder"
	_placeholder.position = Vector2(left_offset, top_offset)
	_placeholder.size = ILLUSTRATION_SIZE
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placeholder.visible = false
	_content_root.add_child(_placeholder)

	_illustration = TextureRect.new()
	_illustration.name = "Illustration"
	_illustration.position = Vector2(left_offset, top_offset)
	_illustration.size = ILLUSTRATION_SIZE
	_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_illustration.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_illustration.visible = false
	_content_root.add_child(_illustration)


func _build_textbox() -> void:
	_textbox_panel = Panel.new()
	_textbox_panel.name = "Textbox"
	_textbox_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_textbox_panel.offset_left = TEXTBOX_MARGIN
	_textbox_panel.offset_right = -TEXTBOX_MARGIN
	_textbox_panel.offset_top = -TEXTBOX_HEIGHT - TEXTBOX_MARGIN
	_textbox_panel.offset_bottom = -TEXTBOX_MARGIN
	_textbox_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_textbox_panel)

	_speaker_label = Label.new()
	_speaker_label.name = "Speaker"
	_speaker_label.add_theme_font_size_override("font_size", FONT_SIZE_SPEAKER)
	_speaker_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1.0))
	_speaker_label.position = Vector2(8, 4)
	_speaker_label.visible = false
	_textbox_panel.add_child(_speaker_label)

	_line_label = RichTextLabel.new()
	_line_label.name = "Line"
	_line_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_LINE)
	_line_label.fit_content = true
	_line_label.bbcode_enabled = true
	_line_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_line_label.offset_left = 10
	_line_label.offset_top = 18
	_line_label.offset_right = -10
	_line_label.offset_bottom = -6
	_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_textbox_panel.add_child(_line_label)


func _build_hint() -> void:
	_hint_label = Label.new()
	_hint_label.name = "Hint"
	var hint_text: String = ADVANCE_HINT
	if _data.skippable:
		hint_text += "   " + SKIP_HINT
	_hint_label.text = hint_text
	_hint_label.add_theme_font_size_override("font_size", FONT_SIZE_HINT)
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 0.85))
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.offset_right = -TEXTBOX_MARGIN - 4
	_hint_label.offset_bottom = -8
	_hint_label.offset_left = -160
	_hint_label.offset_top = -16
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_hint_label)
