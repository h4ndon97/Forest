extends Node

## 소모품 재고 관리.
## 소지량 추적, 사용, 거점 보충.

const ItemDataClass = preload("res://data/items/item_data.gd")
const ConsumableDataClass = preload("res://data/items/consumable_data.gd")

var _registry: Node  # ItemRegistry
var _counts: Dictionary = {}  # consumable_id -> int


func setup(registry: Node) -> void:
	_registry = registry


func add(consumable_id: String, amount: int = 1) -> bool:
	var data: Resource = _registry.get_item(consumable_id)
	if data == null or not data is ConsumableDataClass:
		return false
	var current: int = _counts.get(consumable_id, 0)
	if current >= data.max_carry:
		return false
	_counts[consumable_id] = mini(current + amount, data.max_carry)
	EventBus.consumable_count_changed.emit(consumable_id, _counts[consumable_id], data.max_carry)
	return true


func consume(consumable_id: String) -> Resource:
	var current: int = _counts.get(consumable_id, 0)
	if current <= 0:
		return null
	var data: Resource = _registry.get_item(consumable_id)
	if data == null or not data is ConsumableDataClass:
		return null
	_counts[consumable_id] = current - 1
	EventBus.consumable_count_changed.emit(consumable_id, _counts[consumable_id], data.max_carry)
	return data


func get_count(consumable_id: String) -> int:
	return _counts.get(consumable_id, 0)


func get_all() -> Dictionary:
	return _counts.duplicate()


func refill_all() -> void:
	var consumables: Array = _registry.get_items_by_category(ItemDataClass.ItemCategory.CONSUMABLE)
	for item: Resource in consumables:
		_counts[item.id] = item.max_carry
		EventBus.consumable_count_changed.emit(item.id, item.max_carry, item.max_carry)
	EventBus.consumables_refilled.emit()


func get_save_data() -> Dictionary:
	return {"counts": _counts.duplicate()}


func load_save_data(data: Dictionary) -> void:
	_counts = {}
	var saved: Dictionary = data.get("counts", {})
	for key: String in saved:
		_counts[key] = int(saved[key])
