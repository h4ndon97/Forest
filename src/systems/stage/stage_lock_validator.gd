extends Node

## 스테이지 잠금 검증 컴포넌트.
## 잠금 유형별 접근 가능 여부를 판정한다.
## 시스템 간 직접 참조 없이 EventBus 시그널로 상태를 추적한다.

var _lantern_on: bool = false
var _clear_states: Dictionary = {}   # stage_id -> ClearState (int)
var _sensor_states: Dictionary = {}  # sensor_id -> bool (ENVIRONMENT α)
var _combo_states: Dictionary = {}   # combo_key -> bool (ENVIRONMENT β)


func _ready() -> void:
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	EventBus.stage_clear_updated.connect(_on_clear_updated)
	EventBus.light_sensor_toggled.connect(_on_light_sensor_toggled)
	EventBus.environment_combo_changed.connect(_on_env_combo_changed)


## 스테이지 잠금 검증. 접근 가능 여부와 사유를 반환한다.
func validate(data: StageData) -> Dictionary:
	if data.lock_type == StageData.LockType.NONE:
		return {"accessible": true, "lock_type": data.lock_type, "reason": ""}

	match data.lock_type:
		StageData.LockType.LIGHT:
			return _validate_light(data)
		StageData.LockType.PURIFY:
			return _validate_purify(data)
		StageData.LockType.ENVIRONMENT:
			return _validate_environment(data)
		StageData.LockType.ABILITY:
			return _locked_not_implemented(data, "특수 능력이 필요합니다")
		_:
			return {"accessible": true, "lock_type": data.lock_type, "reason": ""}


## 현재 등불 상태를 반환한다 (외부 조회용).
func is_lantern_on() -> bool:
	return _lantern_on


# --- 내부 ---

func _validate_light(data: StageData) -> Dictionary:
	if _lantern_on:
		return {"accessible": true, "lock_type": data.lock_type, "reason": ""}
	return {
		"accessible": false,
		"lock_type": data.lock_type,
		"reason": "등불을 켜야 진입할 수 있습니다",
	}


func _validate_purify(data: StageData) -> Dictionary:
	## lock_requirement에 스테이지 ID가 지정된 경우 해당 스테이지의 완전 클리어를 요구.
	## 비어 있으면 대상 스테이지 자체의 완전 클리어를 요구.
	var required_stage: String = data.lock_requirement
	if required_stage.is_empty():
		required_stage = data.stage_id

	var state: int = _clear_states.get(required_stage, StageData.ClearState.UNCLEARED)
	if state == StageData.ClearState.FULLY_CLEARED:
		return {"accessible": true, "lock_type": data.lock_type, "reason": ""}
	return {
		"accessible": false,
		"lock_type": data.lock_type,
		"reason": "그림자 잔류를 정화해야 진입할 수 있습니다",
	}


## ENVIRONMENT 잠금 — lock_requirement의 prefix로 α/β/γ 분기.
##   "light_sensor:<sensor_id>" → α
##   "registry:<combo_key>"      → β
##   "flag:<flag_id>"            → γ
func _validate_environment(data: StageData) -> Dictionary:
	var req: String = data.lock_requirement
	if req.is_empty():
		return _locked_not_implemented(data, "환경 도구가 필요합니다")
	var parts: PackedStringArray = req.split(":", true, 1)
	if parts.size() != 2:
		return _locked_not_implemented(data, "환경 도구가 필요합니다")
	return _check_environment_condition(parts[0], parts[1], data)


func _check_environment_condition(prefix: String, value: String, data: StageData) -> Dictionary:
	var satisfied: bool = false
	var locked_reason: String = ""
	match prefix:
		"light_sensor":
			satisfied = _sensor_states.get(value, false)
			locked_reason = "빛으로 센서를 점등해야 합니다"
		"registry":
			satisfied = _combo_states.get(value, false)
			locked_reason = "환경 조건을 맞춰야 합니다"
		"flag":
			satisfied = _is_flag_set(value)
			locked_reason = "특정 조건을 만족해야 합니다"
		_:
			return _locked_not_implemented(data, "환경 도구가 필요합니다")
	if satisfied:
		return {"accessible": true, "lock_type": data.lock_type, "reason": ""}
	return {
		"accessible": false,
		"lock_type": data.lock_type,
		"reason": locked_reason,
	}


func _is_flag_set(flag_id: String) -> bool:
	if has_node("/root/StateFlags"):
		return get_node("/root/StateFlags").has_flag(flag_id)
	return false


func _locked_not_implemented(data: StageData, reason: String) -> Dictionary:
	return {
		"accessible": false,
		"lock_type": data.lock_type,
		"reason": reason,
	}


func _on_lantern_toggled(is_on: bool, _lantern_position: Vector2) -> void:
	_lantern_on = is_on


func _on_clear_updated(stage_id: String, clear_level: int) -> void:
	_clear_states[stage_id] = clear_level


func _on_light_sensor_toggled(sensor_id: String, is_on: bool) -> void:
	_sensor_states[sensor_id] = is_on


func _on_env_combo_changed(combo_key: String, satisfied: bool) -> void:
	_combo_states[combo_key] = satisfied
