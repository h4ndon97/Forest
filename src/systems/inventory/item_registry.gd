extends Node

## 아이템 데이터 레지스트리.
## data/items/ 하위 .tres 파일을 로드하고 ID 기반으로 조회한다.

const ItemDataClass = preload("res://data/items/item_data.gd")

const ITEM_PATHS: Array[String] = [
	"res://data/items/weapons/",
	"res://data/items/armors/",
	"res://data/items/accessories/",
	"res://data/items/consumables/",
]

var _items: Dictionary = {}  # id -> ItemDataClass


func setup() -> void:
	for dir_path in ITEM_PATHS:
		_load_directory(dir_path)
	print("[ItemRegistry] Loaded %d items" % _items.size())


func get_item(item_id: String) -> Resource:
	return _items.get(item_id)


func get_all_items() -> Array:
	return _items.values()


func get_items_by_category(category: int) -> Array:
	var result: Array = []
	for item_id: String in _items:
		var item: Resource = _items[item_id]
		if item.get("category") == category:
			result.append(item)
	return result


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func _load_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := dir_path + file_name
			var res: Resource = load(full_path)
			if res is ItemDataClass and res.id != "":
				_items[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
