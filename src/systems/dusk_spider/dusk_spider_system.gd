extends Node

## 땅거미 시스템 Autoload.
## 시간 흐름 감지 → 스폰 → 이동 → 도착 이벤트를 관리한다.
## 다른 시스템과 직접 참조 없이 EventBus로만 통신한다.

const NavigatorScript = preload("res://src/systems/dusk_spider/dusk_spider_navigator.gd")
const DuskSpiderEntityScript = preload("res://src/systems/dusk_spider/dusk_spider_entity.gd")
const CONFIG_PATH := "res://data/dusk_spider/dusk_spider_config.tres"
const COMBAT_SCENE_PATH := "res://src/entities/enemies/dusk_spider/DuskSpiderCombat.tscn"
const SPAWN_OFFSET_X := 120.0
const HUD_PATH := "res://src/ui/hud/DuskSpiderHud.tscn"

var _config: Resource
var _navigator: Node
var _spiders: Array = []  # Array[DuskSpiderEntity]
var _next_id: int = 0
var _player_stage_id: String = ""
var _is_flowing: bool = false
var _last_closest_distance: int = -1


func _ready() -> void:
	_config = load(CONFIG_PATH)
	_navigator = _create_child("Navigator", NavigatorScript)
	_connect_signals()
	_load_hud.call_deferred()


func _process(delta: float) -> void:
	if not _is_flowing or _spiders.is_empty():
		return

	for spider in _spiders:
		if spider.state != DuskSpiderEntityScript.State.TRACKING:
			continue

		var arrived: bool = spider.advance(delta, _config.seconds_per_map)
		if arrived:
			_on_spider_arrived(spider)
		else:
			# 맵 간 이동 완료 시 다음 구간 설정
			if spider.move_progress == 0.0 and not spider.next_stage_id.is_empty():
				_update_spider_next_step(spider)

	# 프레임당 1회 — 가장 가까운 거리만 발신 (변화 시에만)
	_emit_closest_distance()


## 활성 땅거미 수를 반환한다 (IDLE + TRACKING).
func get_active_count() -> int:
	var count: int = 0
	for spider in _spiders:
		if spider.state != DuskSpiderEntityScript.State.DEFEATED:
			count += 1
	return count


## 특정 스테이지에 도착한 땅거미가 있는지 확인한다.
func has_arrived_at(stage_id: String) -> bool:
	for spider in _spiders:
		if (
			spider.state == DuskSpiderEntityScript.State.ARRIVED
			and spider.current_stage_id == stage_id
		):
			return true
	return false


## 특정 땅거미를 처치한다.
func defeat_spider(spider_id: int) -> void:
	for spider in _spiders:
		if spider.id == spider_id:
			spider.defeat()
			EventBus.dusk_spider_defeated.emit(spider_id)
			_cleanup_defeated()
			break


# --- 내부 ---


func _connect_signals() -> void:
	EventBus.time_flow_started.connect(_on_time_flow_started)
	EventBus.time_flow_stopped.connect(_on_time_flow_stopped)
	EventBus.stage_entered.connect(_on_stage_entered)
	EventBus.dusk_spider_defeated.connect(_on_combat_spider_defeated)


func _on_time_flow_started(_current_hour: float) -> void:
	_is_flowing = true
	if get_active_count() < _config.max_spiders:
		_spawn_spider()
	# 기존 IDLE 땅거미들 추적 재개
	for spider in _spiders:
		if spider.state == DuskSpiderEntityScript.State.IDLE:
			var target: String = _resolve_target()
			if not target.is_empty():
				spider.start_tracking(target, _navigator)


func _on_time_flow_stopped(_current_hour: float) -> void:
	_is_flowing = false
	for spider in _spiders:
		spider.stop_tracking()
	# 경고 해제
	if _last_closest_distance != -1:
		_last_closest_distance = -1
		EventBus.dusk_spider_approached.emit(-1)


func _on_stage_entered(stage_id: String) -> void:
	_player_stage_id = stage_id


func _spawn_spider() -> void:
	if _player_stage_id.is_empty():
		return

	var spawn_stage: String = _pick_spawn_stage()
	if spawn_stage.is_empty():
		return

	var spider := DuskSpiderEntityScript.new(_next_id, spawn_stage)
	_next_id += 1
	_spiders.append(spider)

	var target: String = _resolve_target()
	if not target.is_empty():
		spider.start_tracking(target, _navigator)

	EventBus.dusk_spider_spawned.emit(spider.id)


func _pick_spawn_stage() -> String:
	# 스폰 거리 범위 내에서 랜덤 선택
	for dist in range(_config.spawn_distance_min, _config.spawn_distance_max + 1):
		var candidates: Array = _navigator.get_stages_at_distance(_player_stage_id, dist)
		if not candidates.is_empty():
			candidates.shuffle()
			return candidates[0]

	# 범위 내 후보가 없으면 가장 먼 도달 가능한 스테이지 선택
	for dist in range(_config.spawn_distance_min - 1, 0, -1):
		var candidates: Array = _navigator.get_stages_at_distance(_player_stage_id, dist)
		if not candidates.is_empty():
			candidates.shuffle()
			return candidates[0]

	return ""


func _resolve_target() -> String:
	# 우선순위 1: 플레이어가 있는 FLOWING 스테이지
	if not _player_stage_id.is_empty():
		return _player_stage_id
	return ""


func _on_spider_arrived(spider: RefCounted) -> void:
	var stage_id: String = spider.current_stage_id
	EventBus.dusk_spider_arrived.emit(stage_id)
	# 잔류 부활 요청
	EventBus.residue_revival_requested.emit(stage_id)
	# 적 강화 요청
	(
		EventBus
		. enemy_reinforce_requested
		. emit(
			stage_id,
			_config.reinforce_hp_multiplier,
			_config.reinforce_atk_multiplier,
		)
	)
	# 플레이어가 있는 스테이지에 도착하면 전투 엔티티 스폰
	if stage_id == _player_stage_id:
		_spawn_combat_entity(spider)


func _update_spider_next_step(spider: RefCounted) -> void:
	var next: String = _navigator.get_next_step(spider.current_stage_id, spider.target_stage_id)
	spider.next_stage_id = next


func _emit_closest_distance() -> void:
	var closest: int = _compute_closest_distance()
	if closest != _last_closest_distance:
		_last_closest_distance = closest
		EventBus.dusk_spider_approached.emit(closest)


func _compute_closest_distance() -> int:
	var min_dist: int = -1
	for spider in _spiders:
		if spider.state != DuskSpiderEntityScript.State.TRACKING:
			continue
		var dist: int = spider.get_remaining_distance(_navigator)
		if dist >= 0 and (min_dist < 0 or dist < min_dist):
			min_dist = dist
	return min_dist


func _spawn_combat_entity(spider: RefCounted) -> void:
	if not ResourceLoader.exists(COMBAT_SCENE_PATH):
		push_warning("[땅거미] 전투 씬 없음: %s" % COMBAT_SCENE_PATH)
		return
	var scene_root := get_tree().current_scene
	if not scene_root:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	var scene := load(COMBAT_SCENE_PATH) as PackedScene
	var entity := scene.instantiate()
	entity.spider_id = spider.id
	var offset_x := SPAWN_OFFSET_X if randf() > 0.5 else -SPAWN_OFFSET_X
	scene_root.add_child(entity)
	entity.global_position = player.global_position + Vector2(offset_x, 0)


func _on_combat_spider_defeated(spider_id: int) -> void:
	for spider in _spiders:
		if spider.id == spider_id and spider.state != DuskSpiderEntityScript.State.DEFEATED:
			spider.defeat()
			_cleanup_defeated()
			break


func _cleanup_defeated() -> void:
	var alive: Array = []
	for spider in _spiders:
		if spider.state != DuskSpiderEntityScript.State.DEFEATED:
			alive.append(spider)
	_spiders = alive


func _load_hud() -> void:
	if not ResourceLoader.exists(HUD_PATH):
		return
	var hud := load(HUD_PATH) as PackedScene
	get_tree().root.add_child(hud.instantiate())


func _create_child(child_name: String, script: GDScript) -> Node:
	var node := Node.new()
	node.name = child_name
	node.set_script(script)
	add_child(node)
	return node
