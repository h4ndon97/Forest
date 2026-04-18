extends CanvasLayer

## 스킬 슬롯 HUD.
## 4개 슬롯의 장착 상태, 쿨다운 오버레이, 사용 플래시를 표시한다.

const SkillData = preload("res://data/skills/skill_data.gd")

const MAX_SLOTS := 4
const SLOT_SIZE := 32

# 완만한 오름 호 좌표 (ui_design_master.md §A-5, 640×360 기준, 슬롯 top-left)
# 2026-04-18 개정 1: +44 shift (우측 여백 8px 정렬)
# 2026-04-18 개정 2: -14 shift (Q 슬롯 y=330+32=362로 하단 2px 클립 해결, 하단 여유 확보)
const SLOT_COORDS: Array[Vector2] = [
	Vector2(486, 316),  # Q
	Vector2(524, 311),  # W
	Vector2(562, 305),  # E
	Vector2(600, 298),  # R
]

const COLOR_EMPTY := Color(0.5, 0.5, 0.5, 0.3)
const COLOR_LIGHT := Color(1.0, 0.9, 0.4, 0.9)
const COLOR_SHADOW := Color(0.5, 0.2, 0.7, 0.9)
const COLOR_HYBRID := Color(0.3, 0.8, 0.8, 0.9)
const COLOR_COOLDOWN := Color(0.1, 0.1, 0.1, 0.6)
const COLOR_FLASH := Color(1.0, 1.0, 1.0, 1.0)

const KEY_LABELS := ["U", "I", "K", "L"]

var _slot_backgrounds: Array[ColorRect] = []
var _cooldown_overlays: Array[ColorRect] = []
var _key_labels: Array[Label] = []
var _flash_tween: Tween


func _ready() -> void:
	layer = 10
	_build_ui()

	EventBus.skill_equipped.connect(_on_skill_equipped)
	EventBus.skill_unequipped.connect(_on_skill_unequipped)
	EventBus.skill_used.connect(_on_skill_used)
	EventBus.skill_cooldown_finished.connect(_on_cooldown_finished)

	# 초기 상태 반영
	for i in range(MAX_SLOTS):
		var skill: SkillData = SkillSystem.get_equipped_skill(i)
		if skill:
			_update_slot_color(i, skill.path)
		else:
			_update_slot_color(i, "")


func _process(_delta: float) -> void:
	for i in range(MAX_SLOTS):
		var ratio: float = SkillSystem.get_cooldown_ratio(i)
		if ratio > 0.0:
			_cooldown_overlays[i].visible = true
			_cooldown_overlays[i].size.y = SLOT_SIZE * ratio
		else:
			_cooldown_overlays[i].visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.name = "SlotRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	for i in range(MAX_SLOTS):
		var slot := _create_slot(i)
		slot.position = SLOT_COORDS[i]
		root.add_child(slot)


func _create_slot(index: int) -> Control:
	var panel := Control.new()
	panel.name = "Slot_%d" % index
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

	# 배경
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = COLOR_EMPTY
	bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.add_child(bg)
	_slot_backgrounds.append(bg)

	# 쿨다운 오버레이 (위에서 아래로 sweep)
	var overlay := ColorRect.new()
	overlay.name = "CooldownOverlay"
	overlay.color = COLOR_COOLDOWN
	overlay.size = Vector2(SLOT_SIZE, 0)
	overlay.visible = false
	panel.add_child(overlay)
	_cooldown_overlays.append(overlay)

	# 키 라벨
	var label := Label.new()
	label.name = "KeyLabel"
	label.text = KEY_LABELS[index]
	label.add_theme_font_size_override("font_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.add_child(label)
	_key_labels.append(label)

	return panel


# === 시그널 핸들러 ===


func _on_skill_equipped(slot_index: int, skill_id: String) -> void:
	var skill: SkillData = SkillSystem.get_skill_data(skill_id)
	if skill:
		_update_slot_color(slot_index, skill.path)


func _on_skill_unequipped(slot_index: int) -> void:
	_update_slot_color(slot_index, "")


func _on_skill_used(slot_index: int, _skill_id: String) -> void:
	_flash_slot(slot_index)


func _on_cooldown_finished(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < MAX_SLOTS:
		_cooldown_overlays[slot_index].visible = false


func _update_slot_color(slot_index: int, skill_path: String) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	match skill_path:
		"light":
			_slot_backgrounds[slot_index].color = COLOR_LIGHT
		"shadow":
			_slot_backgrounds[slot_index].color = COLOR_SHADOW
		"hybrid":
			_slot_backgrounds[slot_index].color = COLOR_HYBRID
		_:
			_slot_backgrounds[slot_index].color = COLOR_EMPTY


func _flash_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	var bg: ColorRect = _slot_backgrounds[slot_index]
	var original_color: Color = bg.color
	bg.color = COLOR_FLASH
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(bg, "color", original_color, 0.15)
