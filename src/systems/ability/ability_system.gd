extends Node

## 영구 능력 시스템 (Autoload: AbilitySystem).
## 보유 능력(ability_id → bool) 관리 + 보스 처치 시 보상(능력/포인트/플래그) 분배.
## 능력 데이터는 data/abilities/*.tres를 _ready에서 자동 스캔하여 등록.
## 직렬화는 SaveManager.collect_data/apply_data 경유.

const ABILITIES_DIR := "res://data/abilities/"
const BOSSES_ROOT := "res://data/bosses/"

var _owned: Dictionary = {}  # ability_id -> true
var _ability_data: Dictionary = {}  # ability_id -> AbilityData
var _boss_data: Dictionary = {}  # boss_id -> BossStatsData


func _ready() -> void:
	_load_all_abilities()
	_load_all_bosses()
	EventBus.boss_defeated.connect(_on_boss_defeated)


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

	# 5) 아이템 (현재는 EventBus로 분배만 — InventorySystem이 수신)
	for item_id in data.reward_item_ids:
		if not str(item_id).is_empty():
			EventBus.item_acquired.emit(str(item_id))
