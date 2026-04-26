extends "res://src/entities/objects/environment/base/environment_object.gd"

## 거울/수정 환경 오브젝트.
## STOPPED 중 interact()로 프리셋 각도 회전.
## FLOWING 진입 시 반사 구역 내 적을 분열시킨다 (원본 1체 → 분열체 다수).
## 재분열 가드는 base_enemy.trigger_split 내부에서 처리 (is_spore/_is_revived).

const TimeStateMachineScriptMirror = preload("res://src/systems/time/time_state_machine.gd")

@export var mirror_data: MirrorData
@export var rotation_pivot: Node2D

var _preset_index: int = 0


func _ready() -> void:
	super._ready()
	# REC-MECH-007: finish_light가 그룹 검색으로 빛 굴절 콤보 트리거.
	add_to_group("mirror")
	if mirror_data == null:
		push_warning("Mirror: mirror_data 미설정")
		return
	data = mirror_data
	_preset_index = mirror_data.initial_preset_index
	_apply_rotation()
	EventBus.time_state_changed.connect(_on_time_state_changed)


func _on_interact() -> void:
	if mirror_data == null:
		return
	_preset_index = (_preset_index + 1) % maxi(mirror_data.preset_count, 1)
	_apply_rotation()
	EventBus.environment_interacted.emit(get_instance_id(), _preset_index)


# --- 내부 ---


func _apply_rotation() -> void:
	if mirror_data == null or rotation_pivot == null:
		return
	var step: float = TAU / float(maxi(mirror_data.preset_count, 1))
	rotation_pivot.rotation = step * float(_preset_index)


func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != TimeStateMachineScriptMirror.TimeState.FLOWING:
		return
	if mirror_data == null or not mirror_data.split_on_flow_start:
		return
	_apply_split_to_zone()


func _apply_split_to_zone() -> void:
	if influence_zone == null:
		return
	if not influence_zone.has_method("get_tracked_enemies"):
		return
	var targets: Array = influence_zone.get_tracked_enemies()
	if targets.is_empty():
		return
	var affected: Array = []
	var fallback: String = mirror_data.default_shard_spore_path
	for enemy in targets:
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("trigger_split"):
			continue
		var spawned: Array = enemy.trigger_split(fallback, 0, 0.0)
		if spawned.size() > 0:
			affected.append(enemy.get_instance_id())
	if affected.size() > 0:
		EventBus.environment_split_triggered.emit(get_instance_id(), affected)
