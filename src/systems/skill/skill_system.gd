extends Node

## 스킬 시스템 Autoload.
## 스킬 레지스트리, 슬롯 관리, 피니시 속성 결정, HUD 로드.

const SkillData = preload("res://data/skills/skill_data.gd")
const SlotManagerScript = preload("res://src/systems/skill/skill_slot_manager.gd")
const AttributeResolverScript = preload("res://src/systems/skill/skill_attribute_resolver.gd")
const ExecutorScript = preload("res://src/systems/skill/skill_executor.gd")
const HUD_PATH := "res://src/ui/hud/SkillHud.tscn"

const SKILL_DIR := "res://data/skills/"
## true면 _ready에서 모든 슬롯에 자동 장착(개발/테스트용).
## 인벤토리 [스킬] 탭에서 수동 장착 시연용으로는 false 권장.
const DEBUG_SKILL_AUTO_EQUIP: bool = true

var _all_skills: Dictionary = {}
var _unlocked_skills: Dictionary = {}
var _current_attribute: String = "neutral"

var _slot_manager: Node
var _attribute_resolver: Node


func _ready() -> void:
	_create_components()
	_load_skills()
	_auto_unlock_all()
	if DEBUG_SKILL_AUTO_EQUIP:
		_auto_equip_debug()
	_load_hud.call_deferred()


# === Public API: 슬롯 ===


func equip_skill(slot_index: int, skill_id: String) -> bool:
	if not _all_skills.has(skill_id):
		return false
	if not is_skill_unlocked(skill_id):
		return false
	_slot_manager.equip(slot_index, skill_id)
	_update_attribute()
	EventBus.skill_equipped.emit(slot_index, skill_id)
	return true


func unequip_skill(slot_index: int) -> void:
	_slot_manager.unequip(slot_index)
	_update_attribute()
	EventBus.skill_unequipped.emit(slot_index)


func get_equipped_skill(slot_index: int) -> SkillData:
	var sid: String = _slot_manager.get_skill_id(slot_index)
	if sid.is_empty():
		return null
	return _all_skills.get(sid, null)


# === Public API: 실행 ===


## 슬롯의 스킬을 실행한다. 실패(빈 슬롯/쿨다운/자원 부족) 시 false.
## caster는 현재 Player 고정. MovementComponent/AnimatedSprite2D 자식 노드 규약.
func execute(slot_index: int, caster: Node) -> bool:
	if caster == null:
		return false
	if not can_use_skill(slot_index):
		return false

	var skill: SkillData = get_equipped_skill(slot_index)
	if skill == null:
		return false

	var ctx: Dictionary = {
		"caster": caster,
		"movement": caster.get_node_or_null("MovementComponent"),
		"sprite": caster.get_node_or_null("AnimatedSprite2D"),
		"slot_index": slot_index,
	}
	return ExecutorScript.execute(skill, ctx)


# === Public API: 쿨다운 ===


func can_use_skill(slot_index: int) -> bool:
	var skill: SkillData = get_equipped_skill(slot_index)
	if skill == null:
		return false
	if skill.skill_type != "active":
		return false
	if _slot_manager.is_on_cooldown(slot_index):
		return false
	return true


func start_cooldown(slot_index: int) -> void:
	var skill: SkillData = get_equipped_skill(slot_index)
	if skill == null:
		return
	_slot_manager.start_cooldown(slot_index, skill.cooldown)


func get_cooldown_remaining(slot_index: int) -> float:
	return _slot_manager.get_remaining(slot_index)


func get_cooldown_ratio(slot_index: int) -> float:
	return _slot_manager.get_ratio(slot_index)


# === Public API: 자원 ===


## 슬롯에 장착된 스킬이 현재 시간자원으로 사용 가능한지 검사.
## 빈 슬롯 / time_cost 없음 / 보유 자원 ≥ 필요 자원 → true.
func has_enough_resource(slot_index: int) -> bool:
	var skill: SkillData = get_equipped_skill(slot_index)
	if skill == null or skill.time_cost <= 0.0:
		return true
	var res_data: Dictionary = TimeSystem.get_resource_data()
	return res_data.get("current", 0.0) >= skill.time_cost


# === Public API: 속성 ===


func get_finish_attribute() -> String:
	return _current_attribute


# === Public API: 레지스트리 ===


func get_skill_data(skill_id: String) -> SkillData:
	return _all_skills.get(skill_id, null)


func get_all_skill_ids() -> Array:
	return _all_skills.keys()


func unlock_skill(skill_id: String) -> void:
	if not _all_skills.has(skill_id):
		return
	_unlocked_skills[skill_id] = true
	EventBus.skill_unlocked.emit(skill_id)


func is_skill_unlocked(skill_id: String) -> bool:
	return _unlocked_skills.has(skill_id)


# === 내부 ===


func _create_components() -> void:
	_slot_manager = _create_child("SlotManager", SlotManagerScript)
	_attribute_resolver = _create_child("AttributeResolver", AttributeResolverScript)


func _create_child(child_name: String, script: GDScript) -> Node:
	var node := Node.new()
	node.name = child_name
	node.set_script(script)
	add_child(node)
	return node


## data/skills/ 폴더의 모든 .tres를 런타임 스캔하여 SkillData 인스턴스를 등록한다.
## 신규 스킬 추가 = .tres 파일 드롭만으로 완료(코드 수정 없음).
func _load_skills() -> void:
	var dir := DirAccess.open(SKILL_DIR)
	if dir == null:
		push_warning("SkillSystem: cannot open %s" % SKILL_DIR)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".tres"):
			var path := SKILL_DIR + entry
			var res: Resource = load(path)
			if res is SkillData:
				var skill: SkillData = res as SkillData
				if skill.id.is_empty():
					push_warning("SkillSystem: %s has empty id, skipped" % path)
				else:
					_all_skills[skill.id] = skill
			else:
				push_warning("SkillSystem: %s is not SkillData, skipped" % path)
		entry = dir.get_next()
	dir.list_dir_end()
	print("[SkillSystem] Loaded %d skills" % _all_skills.size())


func _auto_unlock_all() -> void:
	for skill_id in _all_skills:
		_unlocked_skills[skill_id] = true


func _auto_equip_debug() -> void:
	var ids: Array = _all_skills.keys()
	for i in range(mini(ids.size(), _slot_manager.MAX_SLOTS)):
		equip_skill(i, ids[i])


func _update_attribute() -> void:
	var paths: Array = []
	for i in range(_slot_manager.MAX_SLOTS):
		var skill: SkillData = get_equipped_skill(i)
		if skill != null:
			paths.append(skill.path)
	var new_attr: String = _attribute_resolver.resolve(paths)
	if new_attr != _current_attribute:
		_current_attribute = new_attr
		EventBus.finish_attribute_changed.emit(_current_attribute)


func _load_hud() -> void:
	if not ResourceLoader.exists(HUD_PATH):
		return
	var hud_scene: PackedScene = load(HUD_PATH)
	if hud_scene:
		var hud := hud_scene.instantiate()
		get_tree().root.add_child(hud)
		hud.add_to_group("game_hud")
