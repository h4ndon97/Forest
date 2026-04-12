extends Node2D

## 그림자 잔류 마커.
## 적 처치 위치에 남는 시각적 흔적.
## 땅거미 시스템 구현 시 부활 메카닉에 사용된다.

var _enemy_type: String = ""
var _stats_data: EnemyStatsData
var _fallback_marker: ColorRect

const MARKER_SIZE := Vector2(16, 4)
const MARKER_COLOR := Color(0.15, 0.0, 0.2, 0.6)
const PULSE_SPEED := 2.0


func setup(stats_data: EnemyStatsData) -> void:
	_stats_data = stats_data
	_enemy_type = stats_data.enemy_type


func _ready() -> void:
	add_to_group("shadow_residue")
	_create_fallback_marker()


func _process(delta: float) -> void:
	# 잔류 시각 효과: 미세한 투명도 펄스
	if _fallback_marker:
		var pulse := (sin(Time.get_ticks_msec() * 0.001 * PULSE_SPEED) + 1.0) * 0.5
		_fallback_marker.color.a = lerpf(0.3, 0.7, pulse)


func get_enemy_type() -> String:
	return _enemy_type


func get_stats_data() -> EnemyStatsData:
	return _stats_data


## 정화 시 호출 (정화 능력 구현 후 활성화).
func purify() -> void:
	EventBus.residue_purified.emit(global_position)
	queue_free()


func _create_fallback_marker() -> void:
	_fallback_marker = ColorRect.new()
	_fallback_marker.color = MARKER_COLOR
	_fallback_marker.size = MARKER_SIZE
	_fallback_marker.position = Vector2(-MARKER_SIZE.x * 0.5, -MARKER_SIZE.y * 0.5)
	_fallback_marker.z_index = -1
	add_child(_fallback_marker)
