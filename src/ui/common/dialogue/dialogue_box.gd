class_name DialogueBox
extends CanvasLayer

## NPC 대화창 UI.
## NPC가 인스턴스화해 current_scene에 add_child한 뒤 start(data)를 호출한다.
## interact 키로 라인을 순차 진행, 마지막 이후 한 번 더 누르면 닫힌다.
## 대화 중 플레이어 물리 처리는 잠시 꺼서 이동/점프/공격을 차단한다.

const LAYER_INDEX: int = 100
const PANEL_MARGIN: int = 16
const PANEL_HEIGHT: int = 80
const FONT_SIZE_LINE: int = 10
const FONT_SIZE_SPEAKER: int = 9
const FONT_SIZE_HINT: int = 7

var _dialogue_id: String = ""
var _lines: Array[String] = []
var _speaker: String = ""
var _index: int = 0
var _player: Node = null
var _is_armed: bool = false


func start(data: DialogueData) -> void:
	if not data or data.lines.is_empty():
		queue_free()
		return
	_dialogue_id = data.dialogue_id
	_lines = data.lines.duplicate()
	_speaker = data.speaker
	_index = 0
	layer = LAYER_INDEX
	_build_ui()
	_lock_player_input()
	_update_line()
	EventBus.dialogue_started.emit(_dialogue_id)
	call_deferred("_arm")


func _arm() -> void:
	_is_armed = true


func _input(event: InputEvent) -> void:
	if not _is_armed:
		return
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return
	_update_line()


func _update_line() -> void:
	var line_label := get_node_or_null("Panel/LineLabel") as Label
	if line_label:
		line_label.text = _lines[_index]


func _finish() -> void:
	_restore_player_input()
	EventBus.dialogue_finished.emit(_dialogue_id)
	queue_free()


func _lock_player_input() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return
	_player.set_physics_process(false)
	if _player is CharacterBody2D:
		(_player as CharacterBody2D).velocity = Vector2.ZERO


func _restore_player_input() -> void:
	if _player and is_instance_valid(_player):
		_player.set_physics_process(true)


func _build_ui() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = PANEL_MARGIN
	panel.offset_right = -PANEL_MARGIN
	panel.offset_top = -PANEL_HEIGHT - PANEL_MARGIN
	panel.offset_bottom = -PANEL_MARGIN
	add_child(panel)

	if not _speaker.is_empty():
		var spk := Label.new()
		spk.name = "SpeakerLabel"
		spk.text = _speaker
		spk.add_theme_font_size_override("font_size", FONT_SIZE_SPEAKER)
		spk.position = Vector2(8, 4)
		panel.add_child(spk)

	var line_label := Label.new()
	line_label.name = "LineLabel"
	line_label.add_theme_font_size_override("font_size", FONT_SIZE_LINE)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_label.offset_left = 8
	line_label.offset_top = 20
	line_label.offset_right = -8
	line_label.offset_bottom = -20
	panel.add_child(line_label)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "[F] 계속"
	hint.add_theme_font_size_override("font_size", FONT_SIZE_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_right = -8
	hint.offset_bottom = -4
	hint.offset_left = -60
	hint.offset_top = -16
	panel.add_child(hint)
