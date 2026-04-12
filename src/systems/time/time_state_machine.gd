extends Node

## 시간 상태(STOPPED/MANIPULATING/FLOWING)를 관리하고 전이 규칙을 적용한다.

enum TimeState { STOPPED, MANIPULATING, FLOWING }

signal state_changed(old_state: TimeState, new_state: TimeState)

var current_state: TimeState = TimeState.STOPPED
var manipulation_blocked: bool = false


func transition_to(new_state: TimeState) -> void:
	if new_state == current_state:
		return
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


func request_manipulate(has_resource: bool) -> void:
	match current_state:
		TimeState.STOPPED:
			if has_resource and not manipulation_blocked:
				transition_to(TimeState.MANIPULATING)
			else:
				transition_to(TimeState.FLOWING)
		TimeState.FLOWING:
			transition_to(TimeState.STOPPED)


func release_manipulate() -> void:
	if current_state == TimeState.MANIPULATING:
		transition_to(TimeState.FLOWING)


func on_resource_depleted() -> void:
	if current_state == TimeState.MANIPULATING:
		transition_to(TimeState.FLOWING)


func on_manipulation_limit_reached() -> void:
	if current_state == TimeState.MANIPULATING:
		manipulation_blocked = true
		transition_to(TimeState.STOPPED)


func unblock_manipulation() -> void:
	manipulation_blocked = false
