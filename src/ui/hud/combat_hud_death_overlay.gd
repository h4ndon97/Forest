extends Node

## 전투 HUD 사망/리스폰 오버레이 — combat_hud의 child로 작동.
## 사망 시 검정 페이드 + "..." 자막, 리스폰/체크포인트 시 페이드아웃.
## combat_hud.gd에서 분리 (300줄 한계 해소, Pass 5 Step 0).

const FADE_IN_TEXT_COLOR := Color(0.8, 0.2, 0.2, 1.0)
const FADE_OUT_TEXT_COLOR := Color(0.8, 0.2, 0.2, 0.0)
const TEXT_FADE_IN_DURATION: float = 0.3
const FONT_SIZE: int = 12

var _overlay: ColorRect
var _label: Label
var _fade_tween: Tween
var _clear_tween: Tween


func _ready() -> void:
	_create_overlay()
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.checkpoint_entered.connect(_on_checkpoint_respawned)


func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "DeathOverlay"
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_label = Label.new()
	_label.name = "DeathLabel"
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", FADE_OUT_TEXT_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_player_died() -> void:
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0)
	_label.text = ""
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	# 분위기형 죽음 시퀀스 — 검정 풀 페이드 → 자막. 홀드는 combat_system 타이머가 담당.
	var cfg: CombatConfigData = CombatSystem.get_config()
	_fade_tween.tween_property(_overlay, "color", Color(0, 0, 0, 1.0), cfg.respawn_fade_in_duration)
	_fade_tween.tween_callback(
		func():
			_label.text = "..."
			_label.add_theme_color_override("font_color", FADE_OUT_TEXT_COLOR)
	)
	_fade_tween.tween_property(
		_label, "theme_override_colors/font_color", FADE_IN_TEXT_COLOR, TEXT_FADE_IN_DURATION
	)


func _on_player_respawned(_position: Vector2) -> void:
	_clear()


func _on_checkpoint_respawned(_checkpoint_id: String) -> void:
	if not _overlay.visible:
		return
	_clear()


func _clear() -> void:
	if _fade_tween:
		_fade_tween.kill()
	if _clear_tween:
		_clear_tween.kill()
	# stage_transition fade-in 동조 — combat_config의 respawn_fade_out_duration 공유.
	var cfg: CombatConfigData = CombatSystem.get_config()
	var fade_out: float = cfg.respawn_fade_out_duration
	_clear_tween = create_tween().set_parallel(true)
	_clear_tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), fade_out)
	_clear_tween.tween_property(
		_label, "theme_override_colors/font_color", FADE_OUT_TEXT_COLOR, fade_out
	)
	_clear_tween.chain().tween_callback(
		func():
			_overlay.visible = false
			_label.text = ""
	)
