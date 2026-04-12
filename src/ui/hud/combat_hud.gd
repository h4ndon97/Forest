extends CanvasLayer

## 전투 HUD — HP 게이지 + 콤보 인디케이터 + 사망 오버레이.
## EventBus 시그널만 수신하여 갱신한다.

const COMBO_COLOR_NORMAL := Color(0.8, 0.8, 0.8, 0.3)
const COMBO_COLOR_ACTIVE := Color(1.0, 1.0, 1.0, 1.0)
const COMBO_COLOR_FINISH := Color(1.0, 0.85, 0.3, 1.0)

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HpBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HpLabel
@onready var combo_container: HBoxContainer = $MarginContainer/VBoxContainer/ComboContainer

var _combo_indicators: Array[ColorRect] = []
var _death_overlay: ColorRect
var _death_label: Label
var _death_tween: Tween


func _ready() -> void:
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.combo_hit_landed.connect(_on_combo_hit_landed)
	EventBus.combo_finished.connect(_on_combo_finished)
	EventBus.combo_resetted.connect(_on_combo_resetted)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)

	_setup_combo_indicators()
	_create_death_overlay()


func _setup_combo_indicators() -> void:
	for child in combo_container.get_children():
		if child is ColorRect:
			_combo_indicators.append(child)
			child.color = COMBO_COLOR_NORMAL


func _create_death_overlay() -> void:
	_death_overlay = ColorRect.new()
	_death_overlay.name = "DeathOverlay"
	_death_overlay.color = Color(0, 0, 0, 0)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	add_child(_death_overlay)
	_death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_death_label = Label.new()
	_death_label.name = "DeathLabel"
	_death_label.text = ""
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.add_theme_font_size_override("font_size", 12)
	_death_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 0))
	_death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(_death_label)
	_death_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# === HP ===

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if max_hp > 0.0:
		hp_bar.value = current_hp / max_hp * 100.0
	hp_label.text = "%d / %d" % [int(current_hp), int(max_hp)]


# === 콤보 ===

func _on_combo_hit_landed(hit_number: int) -> void:
	if hit_number < 1 or hit_number > _combo_indicators.size():
		return
	var indicator: ColorRect = _combo_indicators[hit_number - 1]
	if hit_number >= _combo_indicators.size():
		indicator.color = COMBO_COLOR_FINISH
	else:
		indicator.color = COMBO_COLOR_ACTIVE


func _on_combo_finished(_attribute: String) -> void:
	if _combo_indicators.size() > 0:
		_combo_indicators[_combo_indicators.size() - 1].color = COMBO_COLOR_FINISH


func _on_combo_resetted() -> void:
	for indicator in _combo_indicators:
		indicator.color = COMBO_COLOR_NORMAL


# === 사망/리스폰 ===

func _on_player_died() -> void:
	_death_overlay.visible = true
	_death_overlay.color = Color(0, 0, 0, 0)
	_death_label.text = ""

	if _death_tween:
		_death_tween.kill()
	_death_tween = create_tween()

	# 화면 어두워짐
	_death_tween.tween_property(_death_overlay, "color", Color(0, 0, 0, 0.6), 0.5)

	# 텍스트 페이드인
	_death_tween.tween_callback(func():
		_death_label.text = "..."
		_death_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 0))
	)
	_death_tween.tween_property(
		_death_label, "theme_override_colors/font_color",
		Color(0.8, 0.2, 0.2, 1.0), 0.3
	)


func _on_player_respawned(_position: Vector2) -> void:
	if _death_tween:
		_death_tween.kill()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_death_overlay, "color", Color(0, 0, 0, 0), 0.3)
	tween.tween_property(
		_death_label, "theme_override_colors/font_color",
		Color(0.8, 0.2, 0.2, 0), 0.2
	)
	tween.chain().tween_callback(func():
		_death_overlay.visible = false
		_death_label.text = ""
	)
