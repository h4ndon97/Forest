extends Node

## 인벤토리/장비 시스템 Autoload.
## 아이템 소지, 장비 장착/해제, 소모품 사용, 보너스 조회를 관리한다.

const ItemDataClass = preload("res://data/items/item_data.gd")
const ConsumableDataClass = preload("res://data/items/consumable_data.gd")
const RegistryScript = preload("res://src/systems/inventory/item_registry.gd")
const EquipmentScript = preload("res://src/systems/inventory/equipment_manager.gd")
const ConsumableScript = preload("res://src/systems/inventory/consumable_manager.gd")
const StatCalcScript = preload("res://src/systems/inventory/equipment_stat_calculator.gd")
const ITEM_DROP_SCENE := preload("res://src/entities/objects/item_drop/ItemDrop.tscn")
const HUD_PATH := "res://src/ui/hud/ConsumableHud.tscn"
const PICKUP_POPUP_PATH := "res://src/ui/hud/ItemPickupPopup.tscn"

var _registry: Node
var _equipment: Node
var _consumables: Node
var _stat_calc: Node

## 소지 아이템 (비소모품, 비장착 상태)
var _bag: Array[String] = []


func _ready() -> void:
	_create_components()
	_connect_signals()
	# load_hud(popup 포함)을 먼저 — starter items emit이 popup connect 후에 가도록.
	_load_hud.call_deferred()
	_debug_give_starter_items.call_deferred()


# === Public API: 아이템 소지 ===


func acquire_item(item_id: String) -> bool:
	var data: Resource = _registry.get_item(item_id)
	if data == null:
		return false
	if data is ConsumableDataClass:
		var added: bool = _consumables.add(item_id)
		if added:
			EventBus.item_acquired.emit(item_id)
		else:
			# 소모품 슬롯 가득 — popup이 사용자에게 알림.
			EventBus.item_pickup_full.emit(item_id)
		return added
	_bag.append(item_id)
	EventBus.item_acquired.emit(item_id)
	print("[Inventory] Acquired: %s" % data.display_name)
	return true


func remove_item(item_id: String) -> bool:
	var idx: int = _bag.find(item_id)
	if idx < 0:
		return false
	_bag.remove_at(idx)
	EventBus.item_removed.emit(item_id)
	return true


func get_bag() -> Array[String]:
	return _bag


func has_item(item_id: String) -> bool:
	return _bag.has(item_id)


func get_item_data(item_id: String) -> Resource:
	return _registry.get_item(item_id)


# === Public API: 장비 ===


func equip_item(slot: int, item_id: String) -> bool:
	var data: Resource = _registry.get_item(item_id)
	if data == null:
		return false
	if not _bag.has(item_id):
		return false
	var prev_id: String = _equipment.equip(slot, item_id)
	_bag.erase(item_id)
	if prev_id != "":
		_bag.append(prev_id)
	_recalculate_stats()
	EventBus.equipment_changed.emit(slot, item_id)
	return true


func unequip_item(slot: int) -> bool:
	var prev_id: String = _equipment.unequip(slot)
	if prev_id == "":
		return false
	_bag.append(prev_id)
	_recalculate_stats()
	EventBus.equipment_changed.emit(slot, "")
	return true


func get_equipped(slot: int) -> String:
	return _equipment.get_equipped(slot)


func get_equipped_data(slot: int) -> Resource:
	var item_id: String = _equipment.get_equipped(slot)
	if item_id == "":
		return null
	return _registry.get_item(item_id)


func auto_equip(item_id: String) -> bool:
	var data: Resource = _registry.get_item(item_id)
	if data == null or not _bag.has(item_id):
		return false
	var slot: int = _equipment.get_slot_for_category(data.category)
	if slot < 0:
		return false
	return equip_item(slot, item_id)


# === Public API: 소모품 ===


func use_consumable(consumable_id: String) -> bool:
	var data: Resource = _consumables.consume(consumable_id)
	if data == null:
		return false
	EventBus.consumable_used.emit(data.consumable_type, data.effect_amount)
	print("[Inventory] Used: %s (%.0f)" % [data.display_name, data.effect_amount])
	return true


func get_consumable_count(consumable_id: String) -> int:
	return _consumables.get_count(consumable_id)


# === Public API: 보너스 조회 (소비 시스템용) ===


func get_attack_bonus() -> float:
	return _stat_calc.get_attack_bonus()


func get_hp_bonus() -> float:
	return _stat_calc.get_hp_bonus()


func get_defense_bonus() -> float:
	return _stat_calc.get_defense_bonus()


func get_time_max_bonus() -> float:
	return _stat_calc.get_time_max_bonus()


func get_time_recovery_bonus() -> float:
	return _stat_calc.get_time_recovery_bonus()


# === Public API: 세이브/로드 ===


func get_save_data() -> Dictionary:
	return {
		"bag": _bag.duplicate(),
		"equipment": _equipment.get_save_data(),
		"consumables": _consumables.get_save_data(),
	}


func load_save_data(data: Dictionary) -> void:
	_bag.clear()
	var saved_bag: Array = data.get("bag", [])
	for item_id in saved_bag:
		_bag.append(str(item_id))
	_equipment.load_save_data(data.get("equipment", {}))
	_consumables.load_save_data(data.get("consumables", {}))
	_recalculate_stats()


# === 디버그 (Phase 3 UI 전까지 임시) ===


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key: InputEventKey = event as InputEventKey
	if key.echo:
		return
	match key.physical_keycode:
		KEY_F10:
			_debug_cycle_weapon()
		KEY_F11:
			_debug_use_consumables()


func _debug_cycle_weapon() -> void:
	var current: String = _equipment.get_equipped(0)
	var weapons: Array = _registry.get_items_by_category(ItemDataClass.ItemCategory.WEAPON)
	if weapons.is_empty():
		return
	var next_idx := 0
	for i in range(weapons.size()):
		if weapons[i].id == current:
			next_idx = (i + 1) % weapons.size()
			break
	var next_weapon: Resource = weapons[next_idx]
	if not _bag.has(next_weapon.id):
		_bag.append(next_weapon.id)
	equip_item(0, next_weapon.id)
	print(
		(
			"[Inventory DEBUG] Weapon → %s (ATK +%.0f)"
			% [next_weapon.display_name, _stat_calc.get_attack_bonus()]
		)
	)


func _debug_use_consumables() -> void:
	use_consumable("hp_potion")
	use_consumable("time_crystal")


# === 내부 ===


func _create_components() -> void:
	_registry = _create_child("ItemRegistry", RegistryScript)
	_registry.setup()
	_equipment = _create_child("EquipmentManager", EquipmentScript)
	_consumables = _create_child("ConsumableManager", ConsumableScript)
	_consumables.setup(_registry)
	_stat_calc = _create_child("EquipStatCalculator", StatCalcScript)
	_stat_calc.setup(_equipment, _registry)


func _create_child(child_name: String, script: GDScript) -> Node:
	var node := Node.new()
	node.name = child_name
	node.set_script(script)
	add_child(node)
	return node


func _connect_signals() -> void:
	EventBus.full_recovery_requested.connect(_on_full_recovery)
	EventBus.enemy_drop_requested.connect(_on_enemy_drop_requested)


func _on_full_recovery() -> void:
	_consumables.refill_all()


## 적 사망 위치에 아이템 드롭 판정. 현재 테스트용 확률 고정.
func _on_enemy_drop_requested(pos: Vector2, _enemy_name: String) -> void:
	var roll: float = randf()
	if roll > 0.3:
		return
	var pool: Array[String] = ["hp_potion", "time_crystal"]
	var drop_id: String = pool[randi() % pool.size()]
	var drop: Area2D = ITEM_DROP_SCENE.instantiate()
	drop.setup_drop(drop_id, pos)
	get_tree().current_scene.add_child(drop)


func _recalculate_stats() -> void:
	_stat_calc.recalculate()
	EventBus.equipment_stats_changed.emit()


func _load_hud() -> void:
	if ResourceLoader.exists(HUD_PATH):
		var hud_scene: PackedScene = load(HUD_PATH)
		if hud_scene:
			var hud := hud_scene.instantiate()
			get_tree().root.add_child(hud)
			hud.add_to_group("game_hud")
	if ResourceLoader.exists(PICKUP_POPUP_PATH):
		var popup_scene: PackedScene = load(PICKUP_POPUP_PATH)
		if popup_scene:
			var popup := popup_scene.instantiate()
			get_tree().root.add_child(popup)
			popup.add_to_group("game_hud")


func _debug_give_starter_items() -> void:
	# Silent — popup 억제. 게임 시작 시 stage_transition 페이드 뒤에 숨거나 도배되는 걸 막음.
	for id in ["sword_basic", "sword_shadow", "leather_vest", "ring_of_strength"]:
		var data: Resource = _registry.get_item(id)
		if data == null or data is ConsumableDataClass:
			continue
		_bag.append(id)
		print("[Inventory] Starter (silent): %s" % data.display_name)
	_consumables.refill_all()
	auto_equip("sword_basic")
	print("[Inventory] Starter items given. F10=cycle weapon, F11=use consumables")
