extends Node

## 월드맵 노드 마우스 호버 라우터 — Stage 0.5.
## WorldMapUI 자식 노드. 그래프 빌드 후 attach()로 각 stage_node에 시그널 연결.
## 호버 변경 시 ui.set_hover_id(stage_id) 호출 → detail panel 갱신.

var _ui: Node


func _ready() -> void:
	_ui = get_parent()


## 새 그래프 빌드 후 호출. 각 stage_node Control에 mouse_entered/exited 연결.
## queue_free된 노드의 시그널은 자동 끊어져 다음 attach가 안전.
func attach(stage_nodes: Dictionary) -> void:
	for stage_id in stage_nodes:
		var node: Control = stage_nodes[stage_id]
		if node == null:
			continue
		if not node.mouse_entered.is_connected(_on_node_entered):
			node.mouse_entered.connect(_on_node_entered.bind(stage_id))
			node.mouse_exited.connect(_on_node_exited.bind(stage_id))


func _on_node_entered(stage_id: String) -> void:
	if _ui and _ui.has_method("set_hover_id"):
		_ui.set_hover_id(stage_id)


func _on_node_exited(stage_id: String) -> void:
	# 현재 hover가 이 노드와 일치할 때만 clear (다른 노드로 즉시 이동한 경우 방어)
	if _ui == null or not _ui.has_method("get_hover_id"):
		return
	if _ui.get_hover_id() == stage_id:
		_ui.set_hover_id("")
