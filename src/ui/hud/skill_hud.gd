extends CanvasLayer

## 스킬 슬롯 HUD 코디네이터.
## 4개 SkillSlot 생성 + 시그널 라우팅 + 쿨다운 프레임 갱신.
## 개별 슬롯 드로잉은 skill_slot.gd / skill_icons.gd 참조.

const SkillData = preload("res://data/skills/skill_data.gd")
const SkillSlot = preload("res://src/ui/hud/skill_slot.gd")

const MAX_SLOTS := 4

# 완만한 오름 호 좌표 (ui_design_master.md §A-5, 640×360 기준, 슬롯 top-left)
const SLOT_COORDS: Array[Vector2] = [
	Vector2(486, 316),  # U
	Vector2(524, 311),  # I
	Vector2(562, 305),  # K
	Vector2(600, 298),  # L
]

const KEY_LABELS: Array[String] = ["U", "I", "K", "L"]

var _slots: Array[SkillSlot] = []


func _ready() -> void:
	layer = 10
	_build_slots()

	EventBus.skill_equipped.connect(_on_skill_equipped)
	EventBus.skill_unequipped.connect(_on_skill_unequipped)
	EventBus.skill_used.connect(_on_skill_used)
	EventBus.skill_cooldown_finished.connect(_on_cooldown_finished)

	for i in range(MAX_SLOTS):
		var skill: SkillData = SkillSystem.get_equipped_skill(i)
		if skill:
			_slots[i].set_skill(skill.id, skill.path, skill.icon_path)
		else:
			_slots[i].set_skill("", "", "")


func _process(_delta: float) -> void:
	for i in range(MAX_SLOTS):
		_slots[i].set_cooldown_ratio(SkillSystem.get_cooldown_ratio(i))


func _build_slots() -> void:
	var root := Control.new()
	root.name = "SlotRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	for i in range(MAX_SLOTS):
		var slot := SkillSlot.new()
		slot.name = "Slot_%d" % i
		slot.position = SLOT_COORDS[i]
		slot.set_key_label(KEY_LABELS[i])
		root.add_child(slot)
		_slots.append(slot)


# === 시그널 핸들러 ===


func _on_skill_equipped(slot_index: int, skill_id: String) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	var skill: SkillData = SkillSystem.get_skill_data(skill_id)
	if skill:
		_slots[slot_index].set_skill(skill.id, skill.path, skill.icon_path)


func _on_skill_unequipped(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index].set_skill("", "", "")


func _on_skill_used(slot_index: int, _skill_id: String) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index].trigger_used_flash()


func _on_cooldown_finished(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index].trigger_ready_flash()
