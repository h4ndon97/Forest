extends CanvasLayer

## 스킬 슬롯 HUD 코디네이터.
## 4 SkillSlot을 우하단에 가로로 배치 (통합 프레임 없음, 개별 슬롯 + 상단 keycap ornament).
## 슬롯 자체 드로잉/keycap은 skill_slot.gd.

const SkillData = preload("res://data/skills/skill_data.gd")
const SkillSlot = preload("res://src/ui/hud/skill_slot.gd")

const MAX_SLOTS := 4
const SLOT_SIZE := 32
const SLOT_GAP := 10  # 슬롯 사이 간격 (프레임 외곽 장식 + 2px 숨쉴 공간)

# 슬롯 위 keycap ornament 영역 (skill_slot.gd가 직접 child로 그림)
const KEYCAP_HEIGHT := 14
const KEYCAP_GAP := 4

# 우하단 클러스터 배치 (640×360, 소모품 바닥선 344에 슬롯 하단 정렬)
const CLUSTER_WIDTH := SLOT_SIZE * MAX_SLOTS + SLOT_GAP * (MAX_SLOTS - 1)  # 128+12=140
const CLUSTER_HEIGHT := KEYCAP_HEIGHT + KEYCAP_GAP + SLOT_SIZE  # 14+4+32=50
const CLUSTER_RIGHT_EDGE := 624  # 소모품 좌측 마진 16과 대칭
const CLUSTER_X := CLUSTER_RIGHT_EDGE - CLUSTER_WIDTH  # 484
const CLUSTER_Y := 344 - CLUSTER_HEIGHT  # 294 (cluster top, keycap top 위치)
const SLOT_Y_OFFSET := KEYCAP_HEIGHT + KEYCAP_GAP  # 18 (cluster 내부 슬롯 y)

const KEY_LABELS: Array[String] = ["U", "I", "K", "L"]

var _slots: Array[SkillSlot] = []


func _ready() -> void:
	layer = 10
	_build_cluster()

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
		_slots[i].set_resource_insufficient(not SkillSystem.has_enough_resource(i))


func _build_cluster() -> void:
	var root := Control.new()
	root.name = "ClusterRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var wrapper := Control.new()
	wrapper.name = "ClusterWrapper"
	wrapper.position = Vector2(CLUSTER_X, CLUSTER_Y)
	wrapper.custom_minimum_size = Vector2(CLUSTER_WIDTH, CLUSTER_HEIGHT)
	wrapper.size = Vector2(CLUSTER_WIDTH, CLUSTER_HEIGHT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wrapper)

	# 슬롯 4개를 4px 간격으로 가로 배치, 슬롯이 keycap 자체적으로 위에 그림
	for i in range(MAX_SLOTS):
		var slot := SkillSlot.new()
		slot.name = "Slot_%d" % i
		slot.position = Vector2(i * (SLOT_SIZE + SLOT_GAP), SLOT_Y_OFFSET)
		slot.set_key_label(KEY_LABELS[i])
		wrapper.add_child(slot)
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
