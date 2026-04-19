extends Node

## 스킬 시스템 Autoload.
## 스킬 레지스트리, 슬롯 관리, 피니시 속성 결정, HUD 로드.

const SkillData = preload("res://data/skills/skill_data.gd")
const SlotManagerScript = preload("res://src/systems/skill/skill_slot_manager.gd")
const AttributeResolverScript = preload("res://src/systems/skill/skill_attribute_resolver.gd")
const HUD_PATH := "res://src/ui/hud/SkillHud.tscn"

const SKILL_PATHS := [
	"res://data/skills/light_slash.tres",
	"res://data/skills/shadow_strike.tres",
]

var _all_skills: Dictionary = {}
var _unlocked_skills: Dictionary = {}
var _current_attribute: String = "neutral"

var _slot_manager: Node
var _attribute_resolver: Node


func _ready() -> void:
	_create_components()
	_load_skills()
	_auto_unlock_all()
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


func _load_skills() -> void:
	for path in SKILL_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var res: Resource = load(path)
		if res is SkillData:
			var skill: SkillData = res as SkillData
			_all_skills[skill.id] = skill


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
