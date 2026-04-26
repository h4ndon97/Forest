extends Node

## 영구 능력 시스템 (Autoload: AbilitySystem).
## 보유 능력(ability_id → bool) 관리 + 보스 처치 시 보상(능력/포인트/플래그) 분배.
## 능력 데이터는 data/abilities/*.tres를 _ready에서 자동 스캔하여 등록.
## 직렬화는 SaveManager.collect_data/apply_data 경유.

const ABILITIES_DIR := "res://data/abilities/"
const BOSSES_ROOT := "res://data/bosses/"
## Phase 4-0 #4 검증용 디버그 토글. true면 디버그 빌드 시작 시 모든 능력 자동 해금.
## - true: 강화 이동 4종 + 후속 공격(Step 5) 회귀 검증 — Phase 4-0 #4 진행 기간 기본값.
## - false: 보스 보상 dispatch(Step 6) 회귀 검증용 — 신규 게임 → 1-B 처치 → light_dash 해금 확인 후 다시 true 복구.
const _DEBUG_AUTO_UNLOCK_ALL := true

var _owned: Dictionary = {}  # ability_id -> true
var _ability_data: Dictionary = {}  # ability_id -> AbilityData
var _boss_data: Dictionary = {}  # boss_id -> BossStatsData


func _ready() -> void:
	_load_all_abilities()
	_load_all_bosses()
	EventBus.boss_defeated.connect(_on_boss_defeated)
	if _DEBUG_AUTO_UNLOCK_ALL and OS.is_debug_build():
		_debug_unlock_all.call_deferred()


func _debug_unlock_all() -> void:
	print(
		(
			"[AbilitySystem DEBUG] auto-unlock all (%d abilities) — see _DEBUG_AUTO_UNLOCK_ALL"
			% _ability_data.size()
		)
	)
	for ability_id in _ability_data.keys():
		unlock(str(ability_id), "debug")


# === Public API: 능력 보유 ===


## 해당 능력을 보유하고 있는지 반환.
func has(ability_id: String) -> bool:
	return _owned.get(ability_id, false)


## 능력을 해금한다. 이미 보유 시 false. 새로 해금되면 시그널 emit + true.
func unlock(ability_id: String, source: String = "") -> bool:
	if ability_id.is_empty():
		return false
	if _owned.get(ability_id, false):
		return false
	_owned[ability_id] = true
	EventBus.ability_unlocked.emit(ability_id)
	var data: AbilityData = _ability_data.get(ability_id, null)
	if data and not data.unlock_story_flag.is_empty() and has_node("/root/StateFlags"):
		get_node("/root/StateFlags").set_flag(data.unlock_story_flag, true)
	if not source.is_empty():
		print("[AbilitySystem] unlock '%s' (source: %s)" % [ability_id, source])
	return true


## 능력 데이터를 반환 (없으면 null).
func get_data(ability_id: String) -> AbilityData:
	return _ability_data.get(ability_id, null)


## 보유 능력 ID 목록.
func get_all_owned() -> Array[String]:
	var out: Array[String] = []
	for k in _owned.keys():
		out.append(str(k))
	return out


# === Public API: 세이브 ===


func get_save_data() -> Dictionary:
	return _owned.duplicate()


func load_save_data(data: Dictionary) -> void:
	_owned.clear()
	for key in data:
		if bool(data[key]):
			_owned[str(key)] = true


# === 내부: 데이터 로딩 ===


func _load_all_abilities() -> void:
	var dir: DirAccess = DirAccess.open(ABILITIES_DIR)
	if dir == null:
		push_warning("AbilitySystem: 능력 디렉터리를 열 수 없음 — " + ABILITIES_DIR)
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var path: String = ABILITIES_DIR + fname
			var res: Resource = ResourceLoader.load(path)
			if res is AbilityData and not (res as AbilityData).id.is_empty():
				_ability_data[(res as AbilityData).id] = res
		fname = dir.get_next()
	dir.list_dir_end()


func _load_all_bosses() -> void:
	_scan_boss_dir(BOSSES_ROOT)


func _scan_boss_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		var full: String = path + fname
		if dir.current_is_dir():
			if fname != "." and fname != "..":
				_scan_boss_dir(full + "/")
		elif fname.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(full)
			if res is BossStatsData and not (res as BossStatsData).boss_id.is_empty():
				_boss_data[(res as BossStatsData).boss_id] = res
		fname = dir.get_next()
	dir.list_dir_end()


# === 내부: 보스 보상 분배 ===


func _on_boss_defeated(boss_id: String) -> void:
	var data: BossStatsData = _boss_data.get(boss_id, null)
	if data == null:
		push_warning("AbilitySystem: boss_defeated 수신 but BossStatsData 미등록 — " + boss_id)
		return
	_dispatch_reward(data)


func _dispatch_reward(data: BossStatsData) -> void:
	# 1) 능력 해금
	if not data.reward_ability_id.is_empty():
		unlock(data.reward_ability_id, "boss:" + data.boss_id)

	# 2) 강화 포인트
	if data.reward_growth_points > 0 and has_node("/root/GrowthSystem"):
		var growth: Node = get_node("/root/GrowthSystem")
		if growth.has_method("earn_growth_points"):
			growth.earn_growth_points(data.reward_growth_points, "boss:" + data.boss_id)
		else:
			push_warning("AbilitySystem: GrowthSystem.earn_growth_points 미정의")

	# 3) 스토리 플래그
	if not data.reward_story_flag.is_empty() and has_node("/root/StateFlags"):
		get_node("/root/StateFlags").set_flag(data.reward_story_flag, true)

	# 4) 다음 구역 해금 플래그
	if not data.reward_next_zone_flag.is_empty() and has_node("/root/StateFlags"):
		get_node("/root/StateFlags").set_flag(data.reward_next_zone_flag, true)

	# 5) 아이템 — InventorySystem.acquire_item 직접 호출.
	#    내부에서 EventBus.item_acquired 자동 emit (팝업 트리거).
	#    이전 구현은 EventBus만 emit해서 팝업은 떠도 가방에는 추가 안 되는 버그였음
	#    (Mire Mother mire_pendant에서 발견 — zone1 oakheart는 reward_item_ids 비어있어 미발견).
	if not data.reward_item_ids.is_empty() and has_node("/root/InventorySystem"):
		var inventory: Node = get_node("/root/InventorySystem")
		if inventory.has_method("acquire_item"):
			for item_id in data.reward_item_ids:
				if not str(item_id).is_empty():
					inventory.acquire_item(str(item_id))
		else:
			push_warning("AbilitySystem: InventorySystem.acquire_item 미정의")
