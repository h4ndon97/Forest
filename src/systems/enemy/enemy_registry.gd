extends Node

## 활성 적 목록을 관리한다.
## EnemySystem의 자식으로 동작하며, 적 등록/해제/일괄 명령을 처리한다.

var _enemies: Dictionary = {}  # id -> enemy node
var _instance_map: Dictionary = {}  # instance_id -> enemy_id
var _next_id: int = 1


func register(enemy: Node) -> int:
	var id := _next_id
	_next_id += 1
	_enemies[id] = enemy
	_instance_map[enemy.get_instance_id()] = id
	return id


func unregister(id: int) -> void:
	var enemy: Node = _enemies.get(id)
	if enemy and is_instance_valid(enemy):
		_instance_map.erase(enemy.get_instance_id())
	_enemies.erase(id)


func get_enemy(id: int) -> Node:
	return _enemies.get(id)


func get_all_enemies() -> Array:
	return _enemies.values()


func get_count() -> int:
	return _enemies.size()


func activate_all() -> void:
	for enemy in _enemies.values():
		if is_instance_valid(enemy) and enemy.has_method("activate"):
			enemy.activate()


func deactivate_all() -> void:
	for enemy in _enemies.values():
		if is_instance_valid(enemy) and enemy.has_method("deactivate"):
			enemy.deactivate()


func get_enemy_by_instance_id(inst_id: int) -> Node:
	var eid: int = _instance_map.get(inst_id, -1)
	if eid < 0:
		return null
	return _enemies.get(eid)


func update_all_intensity(intensity: float) -> void:
	for enemy in _enemies.values():
		if is_instance_valid(enemy) and enemy.has_method("update_intensity"):
			enemy.update_intensity(intensity)
