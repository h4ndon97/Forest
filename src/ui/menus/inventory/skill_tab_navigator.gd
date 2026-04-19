class_name SkillTabNavigator
extends RefCounted

## SkillTab 두 컬럼(슬롯/목록) 간 커서 위치 관리.
## ←→ 컬럼 전환, ↑↓ 컬럼 내 인덱스 이동.

enum Column { SLOTS, LIST }

const SLOT_COUNT: int = 4

var _column: int = Column.SLOTS
var _slot_index: int = 0
var _list_index: int = 0
var _list_size: int = 0


func get_column() -> int:
	return _column


func get_slot_index() -> int:
	return _slot_index


func get_list_index() -> int:
	return _list_index


func set_list_size(size: int) -> void:
	_list_size = size
	if _list_index >= _list_size:
		_list_index = maxi(_list_size - 1, 0)


func navigate_vertical(direction: int) -> void:
	match _column:
		Column.SLOTS:
			_slot_index = wrapi(_slot_index + direction, 0, SLOT_COUNT)
		Column.LIST:
			if _list_size > 0:
				_list_index = wrapi(_list_index + direction, 0, _list_size)


func navigate_horizontal(direction: int) -> void:
	if direction > 0 and _column == Column.SLOTS:
		_column = Column.LIST
	elif direction < 0 and _column == Column.LIST:
		_column = Column.SLOTS


func is_on_slots() -> bool:
	return _column == Column.SLOTS


func is_on_list() -> bool:
	return _column == Column.LIST
