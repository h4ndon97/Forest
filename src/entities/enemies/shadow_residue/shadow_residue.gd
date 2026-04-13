extends Node2D

## 그림자 잔류 마커.
## 적 처치 위치에 남는 시각적 흔적.
## 처치 시간대를 기록하여 반대 시간대에만 정화 가능.
## 땅거미 시스템 구현 시 부활 메카닉에 사용된다.

const PurificationDetectorScript = preload(
	"res://src/entities/enemies/shadow_residue/purification_detector.gd"
)

var _enemy_type: String = ""
var _stats_data: EnemyStatsData
var _killed_during_day: bool = true
var _fallback_marker: ColorRect

const MARKER_SIZE := Vector2(16, 4)
const MARKER_COLOR_DAY := Color(0.15, 0.0, 0.2, 0.6)   # 낮에 처치 — 보라빛
const MARKER_COLOR_NIGHT := Color(0.0, 0.1, 0.2, 0.6)   # 밤에 처치 — 푸른빛
const PULSE_SPEED := 2.0
const DETECTOR_RADIUS := 24.0


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
	EventBus.residue_purified.emit(global_position)
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
