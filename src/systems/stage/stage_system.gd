extends Node

## 스테이지 시스템 Autoload.
## 스테이지 상태(클리어, 잠금)를 관리한다.
## 다른 시스템과 직접 참조 없이 EventBus로만 통신한다.

const RegistryScript = preload("res://src/systems/stage/stage_registry.gd")
const ClearTrackerScript = preload("res://src/systems/stage/stage_clear_tracker.gd")
const TransitionScript = preload("res://src/systems/stage/stage_transition.gd")
const LockValidatorScript = preload("res://src/systems/stage/stage_lock_validator.gd")
const TimePropagationScript = preload("res://src/systems/stage/time_propagation.gd")
const STAGE_DATA_DIR := "res://data/stages/"
const PROPAGATION_CONFIG_PATH := "res://data/stages/propagation_config.tres"
const RESIDUE_SCENE_PATH := "res://src/entities/enemies/shadow_residue/ShadowResidue.tscn"

var _registry: Node
var _clear_tracker: Node
var _transition: CanvasLayer
var _lock_validator: Node
var _time_propagation: Node
var _current_stage_id: String = ""
var _stage_hours: Dictionary = {}    # stage_id -> float (저장된 시각)
var _tracked_hour: float = 12.0      # 현재 시간 시스템의 최신 시각
var _is_flowing: bool = false        # 현재 시간 흐름 상태


func _ready() -> void:
	_registry = Node.new()
	_registry.name = "Registry"
	_registry.set_script(RegistryScript)
	add_child(_registry)

	_clear_tracker = Node.new()
	_clear_tracker.name = "ClearTracker"
	_clear_tracker.set_script(ClearTrackerScript)
	add_child(_clear_tracker)

	_transition = CanvasLayer.new()
	_transition.name = "Transition"
	_transition.set_script(TransitionScript)
	add_child(_transition)

	_lock_validator = Node.new()
	_lock_validator.name = "LockValidator"
	_lock_validator.set_script(LockValidatorScript)
	add_child(_lock_validator)

	_time_propagation = Node.new()
	_time_propagation.name = "TimePropagation"
	_time_propagation.set_script(TimePropagationScript)
	add_child(_time_propagation)

	_load_stage_data()
	_connect_signals()

	var prop_config: PropagationConfigData = load(PROPAGATION_CONFIG_PATH) as PropagationConfigData
	_time_propagation.setup(_registry, _stage_hours, prop_config)


## 현재 스테이지 ID를 반환한다.
func get_current_stage_id() -> String:
	return _current_stage_id


## 스테이지의 클리어 상태를 반환한다.
func get_clear_state(stage_id: String) -> int:
	return _clear_tracker.get_clear_state(stage_id)


## 스테이지 데이터를 반환한다.
func get_stage_data(stage_id: String) -> StageData:
	return _registry.get_stage(stage_id)


## 스테이지의 클리어 진행도를 반환한다.
func get_progress(stage_id: String) -> Dictionary:
	return _clear_tracker.get_progress(stage_id)


## 스테이지 접근 가능 여부를 반환한다 (잠금 검증).
func is_stage_accessible(stage_id: String) -> bool:
	var data: StageData = _registry.get_stage(stage_id)
	if not data:
		return false
	var result: Dictionary = _lock_validator.validate(data)
	return result["accessible"]


## 등록된 모든 스테이지 ID를 반환한다.
func get_all_stage_ids() -> Array:
	return _registry.get_all_stage_ids()


## 스테이지 전환을 실행한다.
func transition_to_stage(target_stage_id: String, entry_direction: String) -> void:
	if _transition.is_transitioning():
		return

	var data: StageData = _registry.get_stage(target_stage_id)
	if not data:
		push_warning("StageSystem: 전환 대상 스테이지가 등록되지 않음: " + target_stage_id)
		return

	var lock_result: Dictionary = _lock_validator.validate(data)
	if not lock_result["accessible"]:
		EventBus.stage_access_denied.emit(
			target_stage_id,
			lock_result["lock_type"],
			lock_result["reason"],
		)
		return

	# 현재 스테이지 시간 저장
	if not _current_stage_id.is_empty():
		_stage_hours[_current_stage_id] = _tracked_hour

	var was_flowing := _is_flowing
	var from_stage := _current_stage_id
	EventBus.stage_transition_started.emit(from_stage, target_stage_id)

	if was_flowing:
		EventBus.time_flow_paused.emit()

	await _transition.execute(data.scene_path, entry_direction)
	EventBus.stage_transition_completed.emit(target_stage_id)

	if was_flowing:
		EventBus.time_flow_resumed.emit()


# --- 내부 ---

func _load_stage_data() -> void:
	var dir := DirAccess.open(STAGE_DATA_DIR)
	if not dir:
		push_warning("StageSystem: 스테이지 데이터 디렉토리를 열 수 없음: " + STAGE_DATA_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := STAGE_DATA_DIR + file_name
			var data: StageData = load(path) as StageData
			if data:
				_registry.register(data)
		file_name = dir.get_next()
	dir.list_dir_end()


func _connect_signals() -> void:
	EventBus.stage_entered.connect(_on_stage_entered)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.residue_left.connect(_on_residue_left)
	EventBus.residue_purified.connect(_on_residue_purified)
	EventBus.stage_transition_requested.connect(_on_transition_requested)
	EventBus.current_hour_changed.connect(_on_hour_changed)
	EventBus.time_flow_started.connect(_on_flow_started)
	EventBus.time_flow_stopped.connect(_on_flow_stopped)


func _on_hour_changed(hour: float) -> void:
	_tracked_hour = hour


func _on_flow_started(_hour: float) -> void:
	_is_flowing = true


func _on_flow_stopped(_hour: float) -> void:
	_is_flowing = false


func _on_transition_requested(target_stage_id: String, entry_direction: String) -> void:
	transition_to_stage(target_stage_id, entry_direction)


func _on_stage_entered(stage_id: String) -> void:
	_current_stage_id = stage_id
	var data: StageData = _registry.get_stage(stage_id)
	if not data:
		push_warning("StageSystem: 등록되지 않은 스테이지 진입: " + stage_id)
		return
	_clear_tracker.init_stage(stage_id, data.total_enemies, data.total_residues)

	# 처치된 적 동기화 (씬 재생성 후 이미 죽은 적 제거용)
	var killed: Array = _clear_tracker.get_killed_enemies(stage_id)
	if not killed.is_empty():
		EventBus.stage_enemies_sync_requested.emit(stage_id, killed)

	# 스테이지별 시간 복원 (저장된 시각 > StageData 초기 시각)
	var hour: float
	if _stage_hours.has(stage_id):
		hour = _stage_hours[stage_id]
	else:
		hour = data.initial_hour
		_stage_hours[stage_id] = hour

	# TimePropagation 확인: 독립 흐름 중인 스테이지면 자동 재개
	var auto_resumed: bool = _time_propagation.notify_stage_entered(stage_id)
	if not auto_resumed:
		if _is_flowing and _time_propagation.is_stage_flowing(stage_id):
			EventBus.time_hour_sync_requested.emit(hour)
		else:
			EventBus.time_set_requested.emit(hour)

	# 저장된 잔류 마커 복원
	var residues: Array = _clear_tracker.get_residues(stage_id)
	if not residues.is_empty():
		_respawn_residues.call_deferred(residues)


func _on_enemy_killed(_enemy_id: int, enemy_name: String) -> void:
	if _current_stage_id.is_empty():
		return
	var new_state: int = _clear_tracker.on_enemy_killed(_current_stage_id, enemy_name)
	if new_state >= 0:
		EventBus.stage_clear_updated.emit(_current_stage_id, new_state)


func _on_residue_left(position: Vector2, killed_during_day: bool) -> void:
	if _current_stage_id.is_empty():
		return
	_clear_tracker.record_residue(_current_stage_id, position, killed_during_day)


func _on_residue_purified(position: Vector2) -> void:
	if _current_stage_id.is_empty():
		return
	var new_state: int = _clear_tracker.on_residue_purified(_current_stage_id, position)
	if new_state >= 0:
		EventBus.stage_clear_updated.emit(_current_stage_id, new_state)


## 저장된 잔류 마커를 현재 씬에 복원한다.
func _respawn_residues(residues: Array) -> void:
	var scene_root := get_tree().current_scene
	if not scene_root:
		return
	if not ResourceLoader.exists(RESIDUE_SCENE_PATH):
		return
	var residue_scene := load(RESIDUE_SCENE_PATH) as PackedScene
	for record in residues:
		var residue := residue_scene.instantiate()
		residue.global_position = record["position"]
		if residue.has_method("setup_from_saved"):
			residue.setup_from_saved(record["killed_during_day"])
		scene_root.add_child(residue)
