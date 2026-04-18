extends BaseNpc

## 상점 NPC.
## 첫 방문 시 인사 대화 1회 → 이후 상점 UI 오픈. 재방문 시 바로 UI.
## 첫 방문 플래그는 shop_id 네임스페이스로 StateFlags에 영속화.

@export var shop_id: String = "default"
@export var shop_items: Array[String] = []
@export var first_greeting: DialogueData

var _is_shop_open: bool = false
var _greeting_pending: bool = false


func _ready() -> void:
	if npc_id.is_empty():
		npc_id = "shop_keeper_%s" % shop_id
	if visual_label.is_empty():
		visual_label = "상점"
	visual_color = Color(0.2, 0.7, 0.3, 0.9)
	super._ready()
	add_to_group("shop_keepers")
	EventBus.shop_closed.connect(func(): _is_shop_open = false)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func get_shop_items() -> Array[String]:
	return shop_items


func npc_interacted() -> void:
	if _is_shop_open or _greeting_pending:
		return
	if first_greeting != null and not _is_greeting_seen():
		_play_first_greeting()
		return
	_open_shop()


func _play_first_greeting() -> void:
	_greeting_pending = true
	set_interaction_blocked(true)
	var box: DialogueBox = DialogueBox.new()
	get_tree().current_scene.add_child(box)
	box.start(first_greeting)


func _on_dialogue_finished(finished_id: String) -> void:
	if not _greeting_pending:
		return
	if first_greeting == null or finished_id != first_greeting.dialogue_id:
		return
	_greeting_pending = false
	set_interaction_blocked(false)
	var flags := _get_state_flags()
	if flags != null:
		flags.set_flag(_greeting_flag_id(), true)
	_open_shop()


func _open_shop() -> void:
	_is_shop_open = true
	EventBus.shop_opened.emit(shop_id)


func _is_greeting_seen() -> bool:
	var flags := _get_state_flags()
	if flags == null:
		return false
	return flags.has_flag(_greeting_flag_id())


func _greeting_flag_id() -> String:
	return "shop_keeper.%s.greeted" % shop_id


func _get_state_flags() -> Node:
	if has_node("/root/StateFlags"):
		return get_node("/root/StateFlags")
	return null
