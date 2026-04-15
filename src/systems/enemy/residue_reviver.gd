extends Node

## 잔류 부활 관리 컴포넌트.
## EnemySystem의 자식으로 동작하며, 부활 요청 시 현재 씬의 잔류를 적으로 되살린다.
## 땅거미 시스템의 EventBus.residue_revival_requested 시그널로 트리거된다.


func _ready() -> void:
	EventBus.residue_revival_requested.connect(_on_revival_requested)


func _on_revival_requested(_stage_id: String) -> void:
	_revive_all_residues()


func _revive_all_residues() -> void:
	var residues := get_tree().get_nodes_in_group("shadow_residue")
	if residues.is_empty():
		return

	for residue in residues:
		if is_instance_valid(residue) and residue.has_method("revive"):
			residue.revive()
