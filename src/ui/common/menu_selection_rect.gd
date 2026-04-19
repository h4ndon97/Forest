class_name MenuSelectionRect
extends ColorRect

## 메뉴 선택 강조 사각형. 호흡 펄스(1.0s 주기, 알파 ±0.10) + 타겟 추적.
## 타이틀/일시정지/인벤토리 메뉴 공통 컴포넌트.

const DEFAULT_COLOR := Color("F2CC66", 0.3)
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.10

var _target: Control = null
var _time: float = 0.0
var _base_alpha: float = DEFAULT_COLOR.a


func _ready() -> void:
	color = DEFAULT_COLOR
	_base_alpha = DEFAULT_COLOR.a
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 타겟 버튼을 지정한다. 이후 매 프레임 해당 버튼의 위치/크기를 추적.
func set_target(ctrl: Control) -> void:
	_target = ctrl
	_sync_to_target()


## 타겟을 해제하면 숨김 처리.
func clear_target() -> void:
	_target = null
	visible = false


func _process(delta: float) -> void:
	_time += delta
	_sync_to_target()
	var breath: float = 0.5 + 0.5 * sin(_time * TAU / BREATH_PERIOD)
	color.a = lerpf(_base_alpha - BREATH_AMPLITUDE, _base_alpha, breath)


func _sync_to_target() -> void:
	if _target == null:
		return
	if not visible:
		visible = true
	global_position = _target.global_position
	size = _target.size
