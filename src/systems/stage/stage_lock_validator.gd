extends Node

## 스테이지 잠금 검증 컴포넌트.
## 잠금 유형별 접근 가능 여부를 판정한다.
## 시스템 간 직접 참조 없이 EventBus 시그널로 상태를 추적한다.

var _lantern_on: bool = false


func _ready() -> void:
	EventBus.lantern_toggled.connect(_on_lantern_toggled)


## 스테이지 잠금 검증. 접근 가능 여부와 사유를 반환한다.
func validate(data: StageData) -> Dictionary:
	if data.lock_type == StageData.LockType.NONE:
		return {"accessible": true, "lock_type": data.lock_type, "reason": ""}

	match data.lock_type:
		StageData.LockType.LIGHT:
			return _validate_light(data)
		StageData.LockType.PURIFY:
			return _locked_not_implemented(data, "정화 능력이 필요합니다")
		StageData.LockType.ENVIRONMENT:
			return _locked_not_implemented(data, "환경 도구가 필요합니다")
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


func _locked_not_implemented(data: StageData, reason: String) -> Dictionary:
	return {
		"accessible": false,
		"lock_type": data.lock_type,
		"reason": reason,
	}


func _on_lantern_toggled(is_on: bool, _lantern_position: Vector2) -> void:
	_lantern_on = is_on
