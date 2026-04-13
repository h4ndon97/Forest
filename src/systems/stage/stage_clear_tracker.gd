extends Node

## 스테이지별 클리어 진행 상태를 추적한다.
## 적 처치 수, 잔류 정화 수를 카운트하고 클리어 레벨을 판정한다.
## 잔류 위치/시간대를 기록하여 스테이지 재진입 시 복원한다.

var _clear_states: Dictionary = {}           # stage_id -> ClearState (int)
var _enemies_killed: Dictionary = {}         # stage_id -> int
var _killed_enemy_names: Dictionary = {}     # stage_id -> Array[String]
var _residues_purified: Dictionary = {}      # stage_id -> int
var _total_enemies: Dictionary = {}          # stage_id -> int
var _total_residues: Dictionary = {}         # stage_id -> int
var _residue_records: Dictionary = {}        # stage_id -> Array[{position, killed_during_day}]


## 스테이지의 클리어 추적을 초기화한다. 재진입 시 기존 상태를 유지한다.
func init_stage(stage_id: String, total_enemies: int, total_residues: int) -> void:
	if _clear_states.has(stage_id):
		return  # 이미 추적 중 — 기존 진행 상태 유지
	_clear_states[stage_id] = StageData.ClearState.UNCLEARED
	_enemies_killed[stage_id] = 0
	_killed_enemy_names[stage_id] = []
	_residues_purified[stage_id] = 0
	_total_enemies[stage_id] = total_enemies
	_total_residues[stage_id] = total_residues
	_residue_records[stage_id] = []


## 적 처치를 기록하고 클리어 상태 전환을 판정한다.
## 상태가 변경되면 새 ClearState를 반환, 변경 없으면 -1.
func on_enemy_killed(stage_id: String, enemy_name: String) -> int:
	if not _clear_states.has(stage_id):
		return -1
	var current_state: int = _clear_states[stage_id]
	if current_state != StageData.ClearState.UNCLEARED:
		return -1

	_enemies_killed[stage_id] += 1
	if not enemy_name.is_empty():
		_killed_enemy_names[stage_id].append(enemy_name)

	var killed: int = _enemies_killed[stage_id]
	var total: int = _total_enemies[stage_id]
	if total > 0 and killed >= total:
		_clear_states[stage_id] = StageData.ClearState.HALF_CLEARED
		return StageData.ClearState.HALF_CLEARED

	return -1


## 해당 스테이지에서 처치된 적 이름 목록을 반환한다.
func get_killed_enemies(stage_id: String) -> Array:
	return _killed_enemy_names.get(stage_id, [])


## 잔류 데이터를 기록한다 (위치 + 처치 시간대).
func record_residue(stage_id: String, pos: Vector2, killed_during_day: bool) -> void:
	if not _residue_records.has(stage_id):
		_residue_records[stage_id] = []
	_residue_records[stage_id].append({
		"position": pos,
		"killed_during_day": killed_during_day,
	})


## 정화된 잔류를 기록에서 제거하고 클리어 상태 전환을 판정한다.
## 상태가 변경되면 새 ClearState를 반환, 변경 없으면 -1.
func on_residue_purified(stage_id: String, pos: Vector2) -> int:
	if not _clear_states.has(stage_id):
		return -1

	# 잔류 기록에서 해당 위치 제거 (가장 가까운 기록)
	_remove_residue_near(stage_id, pos)

	var current_state: int = _clear_states[stage_id]
	if current_state != StageData.ClearState.HALF_CLEARED:
		return -1

	_residues_purified[stage_id] += 1
	var purified: int = _residues_purified[stage_id]
	var total: int = _total_residues[stage_id]
	if total > 0 and purified >= total:
		_clear_states[stage_id] = StageData.ClearState.FULLY_CLEARED
		return StageData.ClearState.FULLY_CLEARED

	return -1


## 미정화 잔류 기록을 반환한다 (스테이지 재진입 시 복원용).
func get_residues(stage_id: String) -> Array:
	return _residue_records.get(stage_id, [])


## 스테이지의 현재 클리어 상태를 반환한다.
func get_clear_state(stage_id: String) -> int:
	return _clear_states.get(stage_id, StageData.ClearState.UNCLEARED)


## 스테이지의 클리어 진행도를 반환한다.
func get_progress(stage_id: String) -> Dictionary:
	return {
		"enemies_killed": _enemies_killed.get(stage_id, 0),
		"total_enemies": _total_enemies.get(stage_id, 0),
		"residues_purified": _residues_purified.get(stage_id, 0),
		"total_residues": _total_residues.get(stage_id, 0),
		"clear_state": _clear_states.get(stage_id, StageData.ClearState.UNCLEARED),
	}


## 위치 기준으로 가장 가까운 잔류 기록을 제거한다.
func _remove_residue_near(stage_id: String, pos: Vector2) -> void:
	var records: Array = _residue_records.get(stage_id, [])
	if records.is_empty():
		return
	var closest_idx := 0
	var closest_dist := pos.distance_squared_to(records[0]["position"])
	for i in range(1, records.size()):
		var dist := pos.distance_squared_to(records[i]["position"])
		if dist < closest_dist:
			closest_dist = dist
			closest_idx = i
	records.remove_at(closest_idx)
