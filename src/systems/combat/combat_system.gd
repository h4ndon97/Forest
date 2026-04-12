extends Node

## 전투 시스템 Autoload.
## 전투 설정 관리, 데미지 계산, 리스폰 처리, 전투 HUD 로드.

const CombatCalculatorScript = preload("res://src/systems/combat/combat_calculator.gd")

const CONFIG_PATH := "res://data/combat/combat_config.tres"
const HUD_PATH := "res://src/ui/hud/CombatHud.tscn"

var _config: CombatConfigData
var _spawn_point: Vector2 = Vector2.ZERO
var _respawn_timer: Timer


func _ready() -> void:
	_config = load(CONFIG_PATH) as CombatConfigData

	_respawn_timer = Timer.new()
	_respawn_timer.name = "RespawnTimer"
	_respawn_timer.one_shot = true
	_respawn_timer.wait_time = _config.respawn_delay
	_respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(_respawn_timer)

	EventBus.player_died.connect(_on_player_died)
	EventBus.spawn_point_set.connect(_on_spawn_point_set)

	_load_hud.call_deferred()


# === Public API ===

func get_config() -> CombatConfigData:
	return _config


func get_combo_damage(hit_number: int) -> float:
	var base: float = CombatCalculatorScript.calculate_hit_damage(hit_number, _config)
	return CombatCalculatorScript.calculate_final_damage(base, _config.finish_attribute)


func set_spawn_point(position: Vector2) -> void:
	_spawn_point = position


func get_spawn_point() -> Vector2:
	return _spawn_point


# === 내부 ===

func _on_spawn_point_set(position: Vector2) -> void:
	_spawn_point = position


func _on_player_died() -> void:
	_respawn_timer.start()


func _on_respawn_timeout() -> void:
	EventBus.player_respawned.emit(_spawn_point)


func _load_hud() -> void:
	if not ResourceLoader.exists(HUD_PATH):
		return
	var hud_scene: PackedScene = load(HUD_PATH)
	if hud_scene:
		var hud := hud_scene.instantiate()
		get_tree().root.add_child(hud)
