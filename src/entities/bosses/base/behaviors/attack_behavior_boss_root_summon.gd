extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 뿌리 소환 공격.
## 텔레그래프 동안 지면 표식 표시 → 표식 위치에 root_count만큼 적 소환.
## 소환 위치: 플레이어 기준 좌우 root_spacing 간격으로 분산.

const BASE_ENEMY_SCENE := "res://src/entities/enemies/base/BaseEnemy.tscn"
const FLOOR_Y := 312.0
const MARKER_SIZE := Vector2(28.0, 6.0)
const FALLBACK_MARKER_COLOR := Color(0.5, 0.2, 0.55, 0.7)

var _pattern: BossPhasePattern = null
var _root_stats: EnemyStatsData = null
var _base_enemy_scene: PackedScene = null

# 0=idle, 1=telegraph, 2=spawned
var _phase_state: int = 0
var _phase_timer: float = 0.0
var _telegraph_duration: float = 0.7
var _spawn_positions: Array = []
var _markers: Array = []


func setup_with_pattern(boss_root: Node2D, base_stats: EnemyStatsData,
		hitbox: Area2D, pattern: BossPhasePattern, attack_index: int = 0) -> void:
	setup(boss_root, base_stats, hitbox)
	_pattern = pattern
	if pattern == null:
		return
	var idx: int = attack_index
	if idx < 0 or idx >= pattern.telegraph_durations.size():
		idx = 0
	if not pattern.telegraph_durations.is_empty():
		_telegraph_duration = pattern.telegraph_durations[idx]
	_load_resources()


func _on_setup() -> void:
	_hitbox.monitoring = false
	_hitbox.monitorable = false


func on_attack_enter() -> void:
	_phase_state = 1
	_phase_timer = 0.0
	_compute_spawn_positions()
	_create_markers()


func on_attack_exit() -> void:
	_phase_state = 0
	_clear_markers()


func on_state_update(delta: float) -> void:
	if _phase_state == 0:
		return
	_phase_timer += delta
	if _phase_state == 1 and _phase_timer >= _telegraph_duration:
		_phase_state = 2
		_clear_markers()
		_spawn_roots()
		on_attack_exit()


# --- 내부 ---

func _load_resources() -> void:
	if not ResourceLoader.exists(BASE_ENEMY_SCENE):
		push_warning("BossRootSummon: BaseEnemy scene not found")
		return
	_base_enemy_scene = load(BASE_ENEMY_SCENE) as PackedScene
	var path: String = _pattern.root_stats_path
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("BossRootSummon: root_stats not set or missing — " + path)
		return
	_root_stats = load(path) as EnemyStatsData


func _compute_spawn_positions() -> void:
	_spawn_positions.clear()
	var count: int = _pattern.root_count
	if count < 1:
		count = 1
	var spacing: float = _pattern.root_spacing
	var anchor: Vector2 = _resolve_anchor()
	# 가운데부터 좌우 균등 분산
	var start_offset: float = -spacing * (count - 1) * 0.5
	for i in count:
		_spawn_positions.append(Vector2(anchor.x + start_offset + spacing * i, FLOOR_Y))


func _resolve_anchor() -> Vector2:
	var target: Node2D = _enemy_root.state_machine.get_target()
	if is_instance_valid(target):
		return Vector2(target.global_position.x, FLOOR_Y)
	return Vector2(_enemy_root.global_position.x, FLOOR_Y)


func _create_markers() -> void:
	_clear_markers()
	var parent: Node = _enemy_root.get_parent()
	if parent == null:
		return
	for pos in _spawn_positions:
		var marker := ColorRect.new()
		marker.color = FALLBACK_MARKER_COLOR
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.size = MARKER_SIZE
		marker.position = pos - MARKER_SIZE * 0.5
		marker.z_index = 4
		parent.add_child(marker)
		_markers.append(marker)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.queue_free()
	_markers.clear()


func _spawn_roots() -> void:
	if _base_enemy_scene == null or _root_stats == null:
		return
	var parent: Node = _enemy_root.get_parent()
	if parent == null:
		return
	for pos in _spawn_positions:
		var enemy: Node = _base_enemy_scene.instantiate()
		enemy.stats_data = _root_stats
		enemy.global_position = pos
		parent.add_child(enemy)
