class_name EffectsFreezable
extends RefCounted

## Phase 3-7 Pass 3 Step 3 — freezable_particles 그룹 speed_scale 토글.
## `EventBus.time_flow_stopped/started` 구독 → 그룹 멤버 일괄 speed_scale 0↔1.
## 플레이어 숨결 등 예외 파티클은 그룹 비가입으로 자동 제외된다.

const GROUP_FREEZABLE: StringName = &"freezable_particles"
const PROP_SPEED_SCALE: StringName = &"speed_scale"

var _host: Node


func _init(host: Node) -> void:
	_host = host
	EventBus.time_flow_stopped.connect(_on_time_flow_stopped)
	EventBus.time_flow_started.connect(_on_time_flow_started)


## 수동 토글 — 디버그/초기화 경로용. 시그널 emit 없이 그룹만 조작.
func apply(frozen: bool) -> void:
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		return
	var scale: float = 0.0 if frozen else 1.0
	tree.call_group(GROUP_FREEZABLE, &"set", PROP_SPEED_SCALE, scale)


# === 내부 ===


func _on_time_flow_stopped(_current_hour: float) -> void:
	apply(true)


func _on_time_flow_started(_current_hour: float) -> void:
	apply(false)
