extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 P2/P3 수장의 잔재 텔레포트 (zone4 Lord Remnant).
## 보스가 그림자 보라 톤으로 사라짐 → 텔포(플레이어 양옆 고정 거리) → 정상 색조 복귀.
## boss_shadow_echo 답습 — 차이점: SHADOW_TINT를 보라 톤(zone4 시그니처)으로 차별화.
## 다중 분신 시각 효과(잔상 ColorRect)는 Step 6 인게임 검증 후 확장 검토 — 안전 추천 단순화.
##
## 주의: 아레나 경계는 zone4 보스 아레나 width=960 가정 hardcoded ([64, 896]).

const FADE_OUT_DURATION := 0.35
const FADE_IN_DURATION := 0.30
const TELEPORT_OFFSET_RANGE := 200.0
const ARENA_MIN_X := 64.0
const ARENA_MAX_X := 896.0
## 수장의 잔재 보라 톤 (zone4 시그니처, zone3 시안과 차별화)
const SHADOW_TINT := Color(0.55, 0.40, 0.65, 1.0)

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
	# 보라 잔재 톤으로 즉시 전환 후 alpha fade out
	_enemy_root.modulate = SHADOW_TINT
	var tween := _enemy_root.create_tween()
	tween.tween_property(_enemy_root, "modulate:a", 0.0, FADE_OUT_DURATION)


func on_attack_exit() -> void:
	_phase_state = 0
	if _enemy_root != null:
		_enemy_root.modulate = Color(1.0, 1.0, 1.0, 1.0)


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
		# 보라 잔재(a=0) → 정상 흰색(a=1) 단일 modulate Color tween
		var tween := _enemy_root.create_tween()
		tween.tween_property(
			_enemy_root, "modulate", Color(1.0, 1.0, 1.0, 1.0), FADE_IN_DURATION
		)
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
	# 아레나 경계 밖으로 나가면 반대 방향으로 폴백
	if target_x < ARENA_MIN_X or target_x > ARENA_MAX_X:
		direction = -direction
		target_x = player.global_position.x + direction * TELEPORT_OFFSET_RANGE
	target_x = clampf(target_x, ARENA_MIN_X, ARENA_MAX_X)
	_enemy_root.global_position = Vector2(target_x, player.global_position.y)
	if _enemy_root.movement_comp != null:
		# 텔포 후 플레이어 향하도록 facing 갱신
		_enemy_root.movement_comp.facing = -direction
