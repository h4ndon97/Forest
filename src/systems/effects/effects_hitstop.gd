class_name EffectsHitstop
extends RefCounted

## Phase 3-7 Pass 1 — 힛스톱 실행기.
## Engine.time_scale을 일시적으로 낮추고 ignore_time_scale 타이머로 복귀.
## 중첩 요청 처리: 누적 금지, 가장 늦게 끝나는 요청 기준으로 갱신.
## get_tree().paused 중에는 동작 거부 (PauseMenu와 충돌 방지).

const NORMAL_SCALE: float = 1.0

var _scene_tree: SceneTree
var _is_active: bool = false
var _scheduled_end_time: float = 0.0
var _hitstop_scale: float = 0.0
var _enabled: bool = true


func _init(tree: SceneTree, scale: float = 0.0, enabled: bool = true) -> void:
	_scene_tree = tree
	_hitstop_scale = clampf(scale, 0.0, 1.0)
	_enabled = enabled


func set_enabled(value: bool) -> void:
	_enabled = value


func set_scale(value: float) -> void:
	_hitstop_scale = clampf(value, 0.0, 1.0)


## 메인 API. duration: 실시간 초. scale_override: 0~1, 음수면 기본 스케일 사용.
func apply(duration: float, scale_override: float = -1.0) -> void:
	if not _enabled or _scene_tree == null or duration <= 0.0:
		return
	if _scene_tree.paused:
		return

	var target_scale: float = _hitstop_scale
	if scale_override >= 0.0:
		target_scale = clampf(scale_override, 0.0, 1.0)
	Engine.time_scale = target_scale

	var end_time: float = Time.get_ticks_msec() / 1000.0 + duration
	if _is_active and end_time <= _scheduled_end_time:
		# 진행 중인 더 긴 요청이 있음. 시간만 이미 갱신된 셈, 새 타이머 만들지 않음.
		return
	_scheduled_end_time = end_time
	_is_active = true

	# ignore_time_scale=true (4번째 인자) — Engine.time_scale=0이어도 타이머 진행
	var timer: SceneTreeTimer = _scene_tree.create_timer(duration, true, false, true)
	timer.timeout.connect(_on_timeout.bind(end_time))


func _on_timeout(scheduled_end_time: float) -> void:
	# 더 늦은 요청이 들어와 갱신됐으면 무시
	if scheduled_end_time < _scheduled_end_time:
		return
	Engine.time_scale = NORMAL_SCALE
	_is_active = false
	_scheduled_end_time = 0.0
