extends BaseNpc

## 스토리 NPC. interact 시 할당된 DialogueData를 DialogueBox로 재생.
## 매번 재생 가능(첫 방문 제한 없음). 대화 중에는 재진입 차단.

@export var dialogue: DialogueData

var _is_dialogue_active: bool = false


func _ready() -> void:
	if npc_id.is_empty():
		npc_id = "story_npc_" + name.to_lower()
	if visual_label.is_empty():
		visual_label = "촌장"
	visual_color = Color(0.7, 0.6, 0.4, 0.9)
	super._ready()
	add_to_group("story_npcs")
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func npc_interacted() -> void:
	if _is_dialogue_active or dialogue == null:
		return
	_is_dialogue_active = true
	set_interaction_blocked(true)
	var box: DialogueBox = DialogueBox.new()
	get_tree().current_scene.add_child(box)
	box.start(dialogue)


func _on_dialogue_finished(finished_id: String) -> void:
	if dialogue == null or finished_id != dialogue.dialogue_id:
		return
	_is_dialogue_active = false
	set_interaction_blocked(false)
