extends Node

## 세이브/로드를 담당하는 StageSystem 자식 컴포넌트.
## 거점 진입 시 게임 상태를 JSON으로 직렬화하여 디스크에 저장한다.
## 게임 시작 시 저장 파일이 있으면 상태를 복원한다.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

var _clear_tracker: Node


func setup(clear_tracker: Node) -> void:
	_clear_tracker = clear_tracker


## 세이브용 전체 데이터를 수집한다.
func collect_data(
	last_checkpoint_id: String,
	stage_hours: Dictionary,
	discovered_checkpoints: Array,
	discovered_stages: Array = [],
) -> Dictionary:
	var data := {
		"last_checkpoint_id": last_checkpoint_id,
		"stage_hours": stage_hours.duplicate(),
		"clear_tracker": _clear_tracker.get_save_data(),
		"discovered_checkpoints": discovered_checkpoints.duplicate(),
		"discovered_stages": discovered_stages.duplicate(),
	}
	if TimeSystem and TimeSystem.has_method("get_resource_data"):
		data["time_resource"] = TimeSystem.get_resource_data()
	if GrowthSystem and GrowthSystem.has_method("get_save_data"):
		data["growth"] = GrowthSystem.get_save_data()
	if InventorySystem and InventorySystem.has_method("get_save_data"):
		data["inventory"] = InventorySystem.get_save_data()
	var state_flags_node: Node = _get_state_flags()
	if state_flags_node != null:
		data["state_flags"] = state_flags_node.get_save_data()
	return data


## 세이브 데이터를 적용한다. 스테이지 레벨 데이터를 Dictionary로 반환.
func apply_data(data: Dictionary) -> Dictionary:
	var result := {}
	result["last_checkpoint_id"] = data.get("last_checkpoint_id", "")
	var saved_hours: Dictionary = data.get("stage_hours", {})
	var stage_hours := {}
	for stage_id in saved_hours:
		stage_hours[stage_id] = float(saved_hours[stage_id])
	result["stage_hours"] = stage_hours
	var tracker_data: Dictionary = data.get("clear_tracker", {})
	if not tracker_data.is_empty():
		_clear_tracker.load_save_data(tracker_data)
	result["discovered_checkpoints"] = data.get("discovered_checkpoints", [])
	result["discovered_stages"] = data.get("discovered_stages", [])
	var growth_data: Dictionary = data.get("growth", {})
	if not growth_data.is_empty() and GrowthSystem and GrowthSystem.has_method("load_save_data"):
		GrowthSystem.load_save_data(growth_data)
	var inv_data: Dictionary = data.get("inventory", {})
	if not inv_data.is_empty() and InventorySystem and InventorySystem.has_method("load_save_data"):
		InventorySystem.load_save_data(inv_data)
	var flags_data: Dictionary = data.get("state_flags", {})
	var state_flags_node: Node = _get_state_flags()
	if state_flags_node != null:
		state_flags_node.load_save_data(flags_data)
	return result


func _get_state_flags() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = (Engine.get_main_loop() as SceneTree).root
	return root.get_node_or_null("StateFlags")


## 게임 상태를 디스크에 저장한다.
func save_game(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("SaveManager: 세이브 파일 쓰기 실패: " + SAVE_PATH)
		return
	file.store_string(json_string)
	file.close()


## 디스크에서 세이브 데이터를 읽어 반환한다. 실패 시 빈 딕셔너리.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("SaveManager: 세이브 파일 읽기 실패: " + SAVE_PATH)
		return {}
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_warning("SaveManager: JSON 파싱 실패: " + json.get_error_message())
		return {}

	var result = json.data
	if not result is Dictionary:
		push_warning("SaveManager: 세이브 데이터가 Dictionary가 아님")
		return {}

	return result


## 세이브 파일 존재 여부를 반환한다.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 세이브 파일을 삭제한다.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
