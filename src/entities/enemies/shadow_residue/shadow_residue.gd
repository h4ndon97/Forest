extends Node2D

## 그림자 잔류 마커.
## 적 처치 위치에 남는 시각적 흔적.
## 처치 시간대를 기록하여 반대 시간대에만 정화 가능.
## 땅거미 시스템 구현 시 부활 메카닉에 사용된다.

const PurificationDetectorScript = preload(
	"res://src/entities/enemies/shadow_residue/purification_detector.gd"
)
const ENEMY_SCENE_PATH := "res://src/entities/enemies/base/BaseEnemy.tscn"
const MARKER_SIZE := Vector2(16, 4)
const MARKER_COLOR_DAY := Color(0.15, 0.0, 0.2, 0.6)  # 낮에 처치 — 보라빛
const MARKER_COLOR_NIGHT := Color(0.0, 0.1, 0.2, 0.6)  # 밤에 처치 — 푸른빛
const PULSE_SPEED := 2.0
const DETECTOR_RADIUS := 40.0
const REVIVE_DURATION := 0.5
const REVIVE_SCALE := Vector2(3.0, 3.0)

var _enemy_type: String = ""
var _stats_data: EnemyStatsData
var _killed_during_day: bool = true
var _fallback_marker: ColorRect
var _reviving: bool = false


func setup(stats_data: EnemyStatsData, killed_during_day: bool = true) -> void:
	_stats_data = stats_data
	_enemy_type = stats_data.enemy_type
	_killed_during_day = killed_during_day


## 저장된 데이터로 복원 시 사용 (스테이지 재진입 시).
func setup_from_saved(killed_during_day: bool) -> void:
	_killed_during_day = killed_during_day


func _ready() -> void:
	add_to_group("shadow_residue")
	_create_fallback_marker()
	_create_purification_detector()


func _process(_delta: float) -> void:
	if _fallback_marker:
		var pulse := (sin(Time.get_ticks_msec() * 0.001 * PULSE_SPEED) + 1.0) * 0.5
		_fallback_marker.color.a = lerpf(0.3, 0.7, pulse)


func get_enemy_type() -> String:
	return _enemy_type


func get_stats_data() -> EnemyStatsData:
	return _stats_data


func get_killed_during_day() -> bool:
	return _killed_during_day


## 정화 시 호출. 정화 조건은 PurificationDetector가 검증한다.
func purify() -> void:
	if _reviving:
		return
	EventBus.residue_purified.emit(global_position)
	queue_free()


## 부활 시 호출. 팽창 연출 후 적을 재소환한다.
func revive() -> void:
	if _reviving:
		return
	_reviving = true

	# 정화 감지 비활성화
	var detector := get_node_or_null("PurificationDetector")
	if detector:
		detector.queue_free()

	# 펄스 중단
	set_process(false)

	# 팽창 + 발광 연출
	var tween := create_tween()
	tween.set_parallel(true)
	(
		tween
		. tween_property(self, "scale", REVIVE_SCALE, REVIVE_DURATION)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	if _fallback_marker:
		var bright := Color(0.6, 0.1, 0.4, 1.0) if _killed_during_day else Color(0.1, 0.3, 0.6, 1.0)
		tween.tween_property(_fallback_marker, "color", bright, REVIVE_DURATION)
	tween.chain().tween_callback(_spawn_revived_enemy)


func _spawn_revived_enemy() -> void:
	if not _stats_data:
		push_warning("ShadowResidue: stats_data 없이 부활 시도 — 건너뜀")
		queue_free()
		return
	if not ResourceLoader.exists(ENEMY_SCENE_PATH):
		queue_free()
		return

	var scene := load(ENEMY_SCENE_PATH) as PackedScene
	var enemy := scene.instantiate()
	enemy.global_position = global_position
	enemy.stats_data = _stats_data

	var config := EnemySystem.get_config()
	if enemy.has_method("setup_as_revived"):
		enemy.setup_as_revived(config.residue_revive_hp_ratio, config.residue_revive_attack_ratio)

	get_parent().add_child(enemy)
	EventBus.residue_revived.emit(global_position, _enemy_type)
	queue_free()


func _create_fallback_marker() -> void:
	var color := MARKER_COLOR_DAY if _killed_during_day else MARKER_COLOR_NIGHT
	_fallback_marker = ColorRect.new()
	_fallback_marker.color = color
	_fallback_marker.size = MARKER_SIZE
	_fallback_marker.position = Vector2(-MARKER_SIZE.x * 0.5, -MARKER_SIZE.y * 0.5)
	_fallback_marker.z_index = -1
	add_child(_fallback_marker)


func _create_purification_detector() -> void:
	var detector := Node2D.new()
	detector.name = "PurificationDetector"
	detector.set_script(PurificationDetectorScript)
	detector.setup(_killed_during_day, DETECTOR_RADIUS)
	add_child(detector)
