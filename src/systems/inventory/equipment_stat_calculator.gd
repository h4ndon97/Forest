extends Node

## 장착 장비의 총합 보너스 계산.
## equipment_changed 시 재계산하여 equipment_stats_changed 시그널로 통보.

const ItemDataClass = preload("res://data/items/item_data.gd")
const WeaponDataClass = preload("res://data/items/weapon_data.gd")
const ArmorDataClass = preload("res://data/items/armor_data.gd")
const AccessoryDataClass = preload("res://data/items/accessory_data.gd")

var _equipment: Node  # EquipmentManager
var _registry: Node  # ItemRegistry

var _attack_bonus: float = 0.0
var _hp_bonus: float = 0.0
var _defense_bonus: float = 0.0
var _time_max_bonus: float = 0.0
var _time_recovery_bonus: float = 0.0


func setup(equipment: Node, registry: Node) -> void:
	_equipment = equipment
	_registry = registry


func recalculate() -> void:
	_attack_bonus = 0.0
	_hp_bonus = 0.0
	_defense_bonus = 0.0
	_time_max_bonus = 0.0
	_time_recovery_bonus = 0.0

	var equipped: Dictionary = _equipment.get_all_equipped()
	for slot: int in equipped:
		var item: Resource = _registry.get_item(equipped[slot])
		if item == null:
			continue
		_add_item_bonuses(item)


func get_attack_bonus() -> float:
	return _attack_bonus


func get_hp_bonus() -> float:
	return _hp_bonus


func get_defense_bonus() -> float:
	return _defense_bonus


func get_time_max_bonus() -> float:
	return _time_max_bonus


func get_time_recovery_bonus() -> float:
	return _time_recovery_bonus


func _add_item_bonuses(item: Resource) -> void:
	if item is WeaponDataClass:
		_attack_bonus += item.attack_bonus
	elif item is ArmorDataClass:
		_hp_bonus += item.hp_bonus
		_defense_bonus += item.defense_bonus
	elif item is AccessoryDataClass:
		_attack_bonus += item.attack_bonus
		_hp_bonus += item.hp_bonus
		_defense_bonus += item.defense_bonus
		_time_max_bonus += item.time_max_bonus
		_time_recovery_bonus += item.time_recovery_bonus
