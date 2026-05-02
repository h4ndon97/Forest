extends Node

## REC-MECH-001 — Echo Nail 시스템.
## EchoTarget을 등록 받고, 외부 호출(Player가 echo_nail 키 입력)에 따라
## 가장 가까운 target의 잔상을 발동한다.
##
## 발동 흐름:
##   1. try_reveal(target) → target.can_reveal() 가드
##   2. EventBus.echo_revealed emit
##   3. echo_data.present_mode 분기 (DialogueBox 또는 OverlaySystem.play_cutscene)
##   4. 매체 종료 시그널(dialogue_finished / cutscene_finished) hook → _finalize_reveal
##   5. _finalize_reveal: GrowthSystem.add_memory_shards + EventBus.echo_finished + mark_consumed
##
## 재진입 차단: _is_revealing 플래그. 매체 자체가 player physics_process를 잠그므로
## 키 연타로 인한 동시 발사는 자연스럽게 막힌다 — 본 가드는 ONE_SHOT 시그널 안전망.

var _registered_targets: Array[EchoTarget] = []
var _is_revealing: bool = false
var _active_target: EchoTarget = null
var _active_data: EchoData = null
var _active_dialogue_id: String = ""


## EchoTarget이 _ready 시점에 자기 등록한다.
func register_target(target: EchoTarget) -> void:
	if target == null or _registered_targets.has(target):
		return
	_registered_targets.append(target)


func unregister_target(target: EchoTarget) -> void:
	_registered_targets.erase(target)


## 플레이어 위치에서 가장 가까운 발동 가능한 target을 찾는다.
func find_closest_revealable(player_pos: Vector2) -> EchoTarget:
	var closest: EchoTarget = null
	var closest_dist_sq: float = INF
	for target in _registered_targets:
		if target == null or not is_instance_valid(target):
			continue
		if not target.can_reveal():
			continue
		var dist_sq: float = player_pos.distance_squared_to(target.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = target
	return closest


## 잔상 발동. 매체 종료까지 비동기.
## 반환: 매체 시작 성공 시 true, 가드 실패 시 false.
func try_reveal(target: EchoTarget) -> bool:
	if _is_revealing:
		return false
	if target == null or not is_instance_valid(target):
		return false
	if not target.can_reveal():
		return false
	var data: EchoData = target.echo_data
	if data == null or data.lines.is_empty():
		return false

	_is_revealing = true
	_active_target = target
	_active_data = data

	EventBus.echo_revealed.emit(data.echo_id, data.subject_type)

	var use_cutscene: bool = data.present_mode == 1 and not data.cutscene_path.is_empty()
	if use_cutscene and ResourceLoader.exists(data.cutscene_path):
		var cutscene_data: CutsceneData = load(data.cutscene_path) as CutsceneData
		if cutscene_data != null and has_node("/root/OverlaySystem"):
			EventBus.cutscene_finished.connect(_on_cutscene_finished, CONNECT_ONE_SHOT)
			OverlaySystem.play_cutscene(cutscene_data)
			return true
		# Cutscene 로드/Overlay 부재 시 Dialogue로 fallback
	return _start_dialogue(data)


func get_registered_count() -> int:
	return _registered_targets.size()


# --- 내부 ---


func _start_dialogue(data: EchoData) -> bool:
	var dialogue: DialogueData = DialogueData.new()
	_active_dialogue_id = "echo_" + data.echo_id
	dialogue.dialogue_id = _active_dialogue_id
	dialogue.speaker = data.subject_label
	dialogue.lines = data.lines.duplicate()

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		_finalize_reveal()
		return false

	var box: DialogueBox = DialogueBox.new()
	current_scene.add_child(box)
	EventBus.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	box.start(dialogue)
	return true


func _on_dialogue_finished(finished_id: String) -> void:
	# 다른 NPC dialogue가 동시에 끝나는 경우는 _is_revealing 가드로 막혀있어 발생하지 않음.
	# 그래도 id 비교로 안전망.
	if finished_id != _active_dialogue_id:
		return
	_finalize_reveal()


func _on_cutscene_finished(_finished_id: String) -> void:
	_finalize_reveal()


func _finalize_reveal() -> void:
	if _active_data != null:
		var shard_gain: int = _active_data.shard_reward
		if shard_gain > 0 and has_node("/root/GrowthSystem"):
			GrowthSystem.add_memory_shards(shard_gain)
		EventBus.echo_finished.emit(_active_data.echo_id, shard_gain)
	if _active_target != null and is_instance_valid(_active_target):
		_active_target.mark_consumed()
	_is_revealing = false
	_active_target = null
	_active_data = null
	_active_dialogue_id = ""
