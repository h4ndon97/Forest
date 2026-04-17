extends Node

## 장비 슬롯 관리.
## 무기 1 + 방어구 1 + 장신구 3 = 총 5슬롯.

enum SlotType { WEAPON, ARMOR, ACCESSORY_0, ACCESSORY_1, ACCESSORY_2 }

const ItemDataClass = preload("res://data/items/item_data.gd")
const SLOT_COUNT := 5

var _slots: Array[String] = ["", "", "", "", ""]


func equip(slot: int, item_id: String) -> String:
	if slot < 0 or slot >= SLOT_COUNT:
		return ""
	var prev := _slots[slot]
	_slots[slot] = item_id
	return prev


func unequip(slot: int) -> String:
	if slot < 0 or slot >= SLOT_COUNT:
		return ""
	var prev := _slots[slot]
	_slots[slot] = ""
	return prev


func get_equipped(slot: int) -> String:
	if slot < 0 or slot >= SLOT_COUNT:
		return ""
	return _slots[slot]


func get_all_equipped() -> Dictionary:
	var result := {}
	for i in range(SLOT_COUNT):
		if _slots[i] != "":
			result[i] = _slots[i]
	return result


func find_empty_accessory_slot() -> int:
	for i in range(SlotType.ACCESSORY_0, SLOT_COUNT):
		if _slots[i] == "":
			return i
	return -1


func get_slot_for_category(category: int) -> int:
	match category:
		ItemDataClass.ItemCategory.WEAPON:
			return SlotType.WEAPON
		ItemDataClass.ItemCategory.ARMOR:
			return SlotType.ARMOR
		ItemDataClass.ItemCategory.ACCESSORY:
			return find_empty_accessory_slot()
	return -1


func clear_all() -> void:
	for i in range(SLOT_COUNT):
		_slots[i] = ""


func get_save_data() -> Dictionary:
	return {"slots": _slots.duplicate()}


func load_save_data(data: Dictionary) -> void:
	var saved_slots: Array = data.get("slots", [])
	for i in range(mini(saved_slots.size(), SLOT_COUNT)):
		_slots[i] = str(saved_slots[i])
