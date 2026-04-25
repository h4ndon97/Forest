extends Node

## 환경 오브젝트 상태 조합 검증 레지스트리 (스테이지 로컬 Node).
## 여러 환경 오브젝트의 상태 프리셋을 집계, 선언된 CombinationRule 만족 여부 판정.
## ENVIRONMENT 잠금 β 유형. 1구역 미사용 — API 골격만 커밋.

signal combination_satisfied(combo_key: String)
signal combination_broken(combo_key: String)

@export var rules: Array[CombinationRule] = []

var _object_states: Dictionary = {}  # object_id -> state_name
var _satisfied: Dictionary = {}  # combo_key -> bool


func _ready() -> void:
	add_to_group("environment_state_registry")
	# 규칙을 false로 초기화 (EventBus 발신은 상태 변화가 실제 일어날 때만)
	for rule in rules:
		if rule != null and not rule.combo_key.is_empty():
			_satisfied[rule.combo_key] = false


## 환경 오브젝트가 시작 시 자신을 등록한다.
func register_object(object_id: String, initial_state_name: String) -> void:
	_object_states[object_id] = initial_state_name
	_recompute()


## 환경 오브젝트가 상태 변화를 보고한다.
func report_state(object_id: String, state_name: String) -> void:
	if _object_states.get(object_id, "") == state_name:
		return
	_object_states[object_id] = state_name
	_recompute()


## 특정 조합의 현재 만족 여부.
func is_combo_satisfied(combo_key: String) -> bool:
	return _satisfied.get(combo_key, false)


## 디버그/세이브용 읽기 전용 복사본.
func get_current_snapshot() -> Dictionary:
	return _object_states.duplicate()


# --- 내부 ---


func _recompute() -> void:
	for rule in rules:
		if rule == null or rule.combo_key.is_empty():
			continue
		var previous: bool = _satisfied.get(rule.combo_key, false)
		var current: bool = _check_rule(rule)
		if current == previous:
			continue
		_satisfied[rule.combo_key] = current
		if current:
			combination_satisfied.emit(rule.combo_key)
		else:
			combination_broken.emit(rule.combo_key)
		EventBus.environment_combo_changed.emit(rule.combo_key, current)


func _check_rule(rule: CombinationRule) -> bool:
	for obj_id in rule.required_states:
		var expected: String = str(rule.required_states[obj_id])
		var actual: String = _object_states.get(obj_id, "")
		if actual != expected:
			return false
	return not rule.required_states.is_empty()
