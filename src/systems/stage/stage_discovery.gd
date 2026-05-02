extends Node

## 스테이지 발견 추적 — 처음 입장한 스테이지 ID 집합 보유.
## StageSystem 자식 노드. 거점 발견(`_discovered_checkpoints`)과는 별개로
## 일반 스테이지까지 포함한 "도달 여부"를 추적한다.
## 미발견 스테이지는 월드맵에서 fog(`???`) 처리.

const START_VILLAGE_ID := "start_village"

var _discovered: Array = []


func _ready() -> void:
	# 시작 마을은 처음부터 발견 상태로 노출.
	if START_VILLAGE_ID not in _discovered:
		_discovered.append(START_VILLAGE_ID)
	EventBus.stage_entered.connect(_on_stage_entered)
	EventBus.game_start_requested.connect(_on_game_start_requested)


func _on_stage_entered(stage_id: String) -> void:
	mark_discovered(stage_id)


func _on_game_start_requested(is_new_game: bool) -> void:
	if is_new_game:
		clear()


func mark_discovered(stage_id: String) -> void:
	if stage_id.is_empty():
		return
	if stage_id not in _discovered:
		_discovered.append(stage_id)


func is_discovered(stage_id: String) -> bool:
	return stage_id in _discovered


func get_all() -> Array:
	return _discovered.duplicate()


func get_save_data() -> Array:
	return _discovered.duplicate()


func load_save_data(data: Array) -> void:
	_discovered.clear()
	if START_VILLAGE_ID not in _discovered:
		_discovered.append(START_VILLAGE_ID)
	for stage_id in data:
		if typeof(stage_id) == TYPE_STRING and stage_id not in _discovered:
			_discovered.append(stage_id)


func clear() -> void:
	_discovered.clear()
	_discovered.append(START_VILLAGE_ID)
