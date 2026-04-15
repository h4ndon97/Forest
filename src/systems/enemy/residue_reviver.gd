extends Node

## 잔류 부활 관리 컴포넌트.
## EnemySystem의 자식으로 동작하며, 부활 요청 시 현재 씬의 잔류를 적으로 되살린다.
## 디버그 모드에서 R키로 수동 부활을 트리거할 수 있다.
## 땅거미 시스템 구현 시 디버그 트리거를 제거하고
## EventBus.residue_revival_requested 시그널로 대체한다.

const DEBUG_REVIVE_KEY := KEY_R

## false로 설정하면 디버그 키 비활성화 (땅거미 구현 시 변경)
var _debug_enabled: bool = true


func _ready() -> void:
	EventBus.residue_revival_requested.connect(_on_revival_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not _debug_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == DEBUG_REVIVE_KEY:
		_revive_all_residues()


func _on_revival_requested(_stage_id: String) -> void:
	_revive_all_residues()


func _revive_all_residues() -> void:
	var residues := get_tree().get_nodes_in_group("shadow_residue")
	if residues.is_empty():
		return

	for residue in residues:
		if is_instance_valid(residue) and residue.has_method("revive"):
			residue.revive()
