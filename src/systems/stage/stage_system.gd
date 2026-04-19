extends Node

## 스테이지 시스템 Autoload.
## 스테이지 상태(클리어, 잠금)를 관리한다.
## 다른 시스템과 직접 참조 없이 EventBus로만 통신한다.

const RegistryScript = preload("res://src/systems/stage/stage_registry.gd")
const ClearTrackerScript = preload("res://src/systems/stage/stage_clear_tracker.gd")
const TransitionScript = preload("res://src/systems/stage/stage_transition.gd")
const LockValidatorScript = preload("res://src/systems/stage/stage_lock_validator.gd")
const TimePropagationScript = preload("res://src/systems/stage/time_propagation.gd")
const SaveManagerScript = preload("res://src/systems/stage/save_manager.gd")
const STAGE_DATA_DIR := "res://data/stages/"
const PROPAGATION_CONFIG_PATH := "res://data/stages/propagation_config.tres"

var _registry: Node
var _clear_tracker: Node
var _transition: CanvasLayer
var _lock_validator: Node
var _time_propagation: Node
var _save_manager: Node
var _current_stage_id: String = ""
var _last_checkpoint_id: String = ""
var _stage_hours: Dictionary = {}  # stage_id -> float (저장된 시각)
var _tracked_hour: float = 12.0  # 현재 시간 시스템의 최신 시각
var _is_flowing: bool = false  # 현재 시간 흐름 상태
var _discovered_checkpoints: Array = []  # 발견한 거점 ID 목록


func _ready() -> void:
	_registry = _add_child_node("Registry", RegistryScript)
	_clear_tracker = _add_child_node("ClearTracker", ClearTrackerScript)
	_clear_tracker.setup_residue_scene(
		"res://src/entities/enemies/shadow_residue/ShadowResidue.tscn"
	)
	_transition = _add_child_canvas("Transition", TransitionScript)
	_lock_validator = _add_child_node("LockValidator", LockValidatorScript)
	_time_propagation = _add_child_node("TimePropagation", TimePropagationScript)
	_save_manager = _add_child_node("SaveManager", SaveManagerScript)
	_save_manager.setup(_clear_tracker)

	_load_stage_data()
	_connect_signals()

	var prop_config: PropagationConfigData = load(PROPAGATION_CONFIG_PATH) as PropagationConfigData
	_time_propagation.setup(_registry, _stage_hours, prop_config)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_delete_save"):
		_save_manager.delete_save()
		_last_checkpoint_id = ""
		push_warning("StageSystem: 세이브 삭제됨 (재시작 시 반영)")


func get_current_stage_id() -> String:
	return _current_stage_id


func get_clear_state(stage_id: String) -> int:
	return _clear_tracker.get_clear_state(stage_id)


func get_stage_data(stage_id: String) -> StageData:
	return _registry.get_stage(stage_id)


func get_progress(stage_id: String) -> Dictionary:
	return _clear_tracker.get_progress(stage_id)


func is_stage_accessible(stage_id: String) -> bool:
	var data: StageData = _registry.get_stage(stage_id)
	if not data:
		return false
	return _lock_validator.validate(data)["accessible"]


func get_all_stage_ids() -> Array:
	return _registry.get_all_stage_ids()


func get_last_checkpoint_id() -> String:
	return _last_checkpoint_id


## 세이브 파일 존재 여부 (타이틀 "이어하기" 활성화 판단용).
func has_save_file() -> bool:
	if not _save_manager:
		return false
	if not _save_manager.has_save():
		return false
	# 세이브는 있으나 last_checkpoint_id가 비면 이어하기 불가
	var data: Dictionary = _save_manager.load_game()
	return not String(data.get("last_checkpoint_id", "")).is_empty()


func get_discovered_checkpoints() -> Array:
	return _discovered_checkpoints.duplicate()


func get_stage_hour(stage_id: String) -> float:
	if _stage_hours.has(stage_id):
		return _stage_hours[stage_id]
	var data: StageData = _registry.get_stage(stage_id)
	if data:
		return data.initial_hour
	return 12.0


func transition_to_stage(target_stage_id: String, entry_direction: String) -> void:
	if _transition.is_transitioning():
		return

	var data: StageData = _registry.get_stage(target_stage_id)
	if not data:
		push_warning("StageSystem: 전환 대상 스테이지가 등록되지 않음: " + target_stage_id)
		return

	var lock_result: Dictionary = _lock_validator.validate(data)
	if not lock_result["accessible"]:
		(
			EventBus
			. stage_access_denied
			. emit(
				target_stage_id,
				lock_result["lock_type"],
				lock_result["reason"],
			)
		)
		return

	# 현재 스테이지 시간 저장 + 거점 이탈 시그널
	if not _current_stage_id.is_empty():
		var current_data: StageData = _registry.get_stage(_current_stage_id)
		if current_data and current_data.is_checkpoint:
			EventBus.checkpoint_exited.emit(_current_stage_id)
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


func load_save_data(data: Dictionary) -> void:
	var result: Dictionary = _save_manager.apply_data(data)
	_last_checkpoint_id = result["last_checkpoint_id"]
	for stage_id in result["stage_hours"]:
		_stage_hours[stage_id] = result["stage_hours"][stage_id]
	for cp_id in result["discovered_checkpoints"]:
		if cp_id not in _discovered_checkpoints:
			_discovered_checkpoints.append(cp_id)


# --- 내부 ---


## 세이브 파일이 있으면 상태를 복원하고 거점으로 전환한다.
func _try_load_save() -> void:
	if not _save_manager.has_save():
		return
	var data: Dictionary = _save_manager.load_game()
	if data.is_empty():
		return
	load_save_data(data)

	# 초기 씬 로드 완료 후 거점으로 전환 (검정 화면은 _ready에서 이미 적용됨)
	if not _last_checkpoint_id.is_empty():
		await get_tree().process_frame
		EventBus.stage_transition_requested.emit(_last_checkpoint_id, "checkpoint")


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
	EventBus.residue_revived.connect(_on_residue_revived)
	EventBus.stage_transition_requested.connect(_on_transition_requested)
	EventBus.game_start_requested.connect(_on_game_start_requested)
	EventBus.current_hour_changed.connect(func(hour: float): _tracked_hour = hour)
	EventBus.time_flow_started.connect(func(_hour: float): _is_flowing = true)
	EventBus.time_flow_stopped.connect(func(_hour: float): _is_flowing = false)


func _on_game_start_requested(is_new_game: bool) -> void:
	if is_new_game:
		if _save_manager.has_save():
			_save_manager.delete_save()
		_last_checkpoint_id = ""
		_stage_hours.clear()
		_discovered_checkpoints.clear()
		EventBus.stage_transition_requested.emit("start_village", "checkpoint")
	else:
		_transition.set_fade_black()
		_try_load_save()


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
		_clear_tracker.respawn_residues_in_scene.call_deferred(residues)

	# 거점 감지: 발견 등록 + 완전 회복 + 세이브 트리거
	if data.is_checkpoint:
		_last_checkpoint_id = stage_id
		if stage_id not in _discovered_checkpoints:
			_discovered_checkpoints.append(stage_id)
		EventBus.checkpoint_entered.emit(stage_id)
		EventBus.full_recovery_requested.emit()
		var save_data: Dictionary = (
			_save_manager
			. collect_data(
				_last_checkpoint_id,
				_stage_hours,
				_discovered_checkpoints,
			)
		)
		_save_manager.save_game(save_data)


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


func _on_residue_revived(position: Vector2, _enemy_type: String) -> void:
	if _current_stage_id.is_empty():
		return
	_clear_tracker.remove_residue_record(_current_stage_id, position)


func _add_child_node(node_name: String, script: GDScript) -> Node:
	var n := Node.new()
	n.name = node_name
	n.set_script(script)
	add_child(n)
	return n


func _add_child_canvas(node_name: String, script: GDScript) -> CanvasLayer:
	var c := CanvasLayer.new()
	c.name = node_name
	c.set_script(script)
	add_child(c)
	return c
