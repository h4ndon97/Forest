extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 P2 반사면 텔레포트 (zone2 Mire Mother).
## 보스가 페이드아웃 → 텔포(플레이어 양옆 고정 거리) → 페이드인 → 종료.
## 데미지 없는 위치 변경 패턴 — cooldown 후 다른 패턴(ranged_spread)이 cycle로 진입해 압박.
## 흐름: fade_out(0.4s) → invisible(telegraph_duration) → fade_in(0.3s) → exit.
##
## 주의: 현재는 ReflectiveFloor 위치 쿼리 인프라 부재 — 플레이어 ±200px 랜덤 오프셋으로 대체.
## Phase 4-A 진입 시 ReflectiveFloor.get_nearest_anchor() API 추가 가능 (선택).

const FADE_OUT_DURATION := 0.4
const FADE_IN_DURATION := 0.3
const TELEPORT_OFFSET_RANGE := 200.0
## 아레나 경계 안전 마진. boss_data 또는 stage room_size에서 가져올 수도 있으나
## 현재 zone2 보스 아레나 width=960 기준 hardcoded ([64, 896]) — 보스 폭(56) 여유 포함.
const ARENA_MIN_X := 64.0
const ARENA_MAX_X := 896.0

var _pattern: BossPhasePattern = null
var _telegraph_duration: float = 0.5

# 0=idle, 1=fade_out, 2=invisible(텔포 후 대기), 3=fade_in
var _phase_state: int = 0
var _phase_timer: float = 0.0


func setup_with_pattern(
	boss_root: Node2D, base_stats: EnemyStatsData, pattern: BossPhasePattern, attack_index: int = 0
) -> void:
	setup(boss_root, base_stats)
	_pattern = pattern
	if pattern == null:
		return
	var idx: int = attack_index
	if idx < 0 or idx >= pattern.telegraph_durations.size():
		idx = 0
	if not pattern.telegraph_durations.is_empty():
		_telegraph_duration = pattern.telegraph_durations[idx]


func on_attack_enter() -> void:
	if _enemy_root == null:
		return
	_phase_state = 1
	_phase_timer = 0.0
	var tween := _enemy_root.create_tween()
	tween.tween_property(_enemy_root, "modulate:a", 0.0, FADE_OUT_DURATION)


func on_attack_exit() -> void:
	_phase_state = 0
	if _enemy_root != null:
		_enemy_root.modulate.a = 1.0


func on_state_update(delta: float) -> void:
	if _phase_state == 0:
		return
	_phase_timer += delta
	if _phase_state == 1 and _phase_timer >= FADE_OUT_DURATION:
		_phase_state = 2
		_phase_timer = 0.0
		_perform_teleport()
	elif _phase_state == 2 and _phase_timer >= _telegraph_duration:
		_phase_state = 3
		_phase_timer = 0.0
		var tween := _enemy_root.create_tween()
		tween.tween_property(_enemy_root, "modulate:a", 1.0, FADE_IN_DURATION)
	elif _phase_state == 3 and _phase_timer >= FADE_IN_DURATION:
		on_attack_exit()


func _perform_teleport() -> void:
	if _enemy_root == null:
		return
	var player: Node2D = _enemy_root.get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var direction: float = 1.0 if randf() > 0.5 else -1.0
	var target_x: float = player.global_position.x + direction * TELEPORT_OFFSET_RANGE
	# 아레나 경계 밖으로 나가면 반대 방향으로 폴백 (player 중앙 부근일 때만 양쪽 가능)
	if target_x < ARENA_MIN_X or target_x > ARENA_MAX_X:
		direction = -direction
		target_x = player.global_position.x + direction * TELEPORT_OFFSET_RANGE
	target_x = clampf(target_x, ARENA_MIN_X, ARENA_MAX_X)
	_enemy_root.global_position = Vector2(target_x, player.global_position.y)
	if _enemy_root.movement_comp != null:
		# 텔포 후 플레이어 향하도록 facing 갱신
		_enemy_root.movement_comp.facing = -direction
