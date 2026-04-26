class_name EffectsTimeStopShutter
extends RefCounted

## REC-FX-001 — 시간 정지 발동 순간 0.15초 셔터 임팩트.
## EventBus.time_flow_stopped 구독 → 색수차 보간 + 화면 플래시.
## 기존 EffectsTimeStop(세피아 weight 0→1)과 같은 셰이더의 다른 uniform(chromatic_strength)을 건드림.
##
## 시퀀스 (총 0.15초):
##   0.00s: chromatic 0 → max + 흰 플래시 시작
##   0.075s: chromatic 절정 (max)
##   0.15s: chromatic max → 0
##   이후: EffectsTimeStop이 세피아/잔상/블루펄스 계속 진행

const PARAM_CHROMATIC: StringName = &"chromatic_strength"

var _host: Node
var _config: EffectsConfigData
var _tween: Tween = null


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	EventBus.time_flow_stopped.connect(_on_time_flow_stopped)
	EventBus.time_flow_started.connect(_on_time_flow_started)


# === 내부 ===


func _on_time_flow_stopped(_current_hour: float) -> void:
	_play_shutter()


func _on_time_flow_started(_current_hour: float) -> void:
	# 흐름 재개 시 셔터 효과는 이미 끝났을 것. 안전을 위해 chromatic 0으로 리셋.
	_kill_tween()
	OverlaySystem.set_post_process_param(PARAM_CHROMATIC, 0.0)


func _play_shutter() -> void:
	if _host == null or _config == null:
		return
	# 화면 플래시 (백색 짧은 깜빡임).
	if _config.shutter_flash_alpha > 0.0:
		var flash_color: Color = _config.shutter_flash_color
		flash_color.a = _config.shutter_flash_alpha
		_host.request_screen_flash(flash_color, _config.shutter_duration)
	# 색수차 0 → max → 0 보간.
	_kill_tween()
	var max_strength: float = _config.shutter_chromatic_max
	var half: float = _config.shutter_duration * 0.5
	if max_strength <= 0.0 or half <= 0.0:
		return
	_tween = _host.create_tween().set_ignore_time_scale(true)
	_tween.tween_method(_set_chromatic, 0.0, max_strength, half)
	_tween.tween_method(_set_chromatic, max_strength, 0.0, half)


func _set_chromatic(value: float) -> void:
	OverlaySystem.set_post_process_param(PARAM_CHROMATIC, value)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
