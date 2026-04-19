class_name InventoryTabController
extends Node

## 인벤토리 탭 스트립([장비] / [스킬]) 헤더 표시 + 활성 탭 시각화.
## 입력 처리는 inventory_menu(상위)에서 Q/E를 받아 set_active_tab으로 위임.

signal tab_changed(index: int)

const COLOR_ACTIVE := Color("F2CC66")
const COLOR_INACTIVE := Color("8A8070")
const TAB_NAMES := ["장비", "스킬"]
const FONT_SIZE: int = 11
const TAB_SPACING: float = 18.0

var _root: Control
var _labels: Array[Label] = []
var _active_index: int = 0


func setup(parent: Control) -> void:
	_root = Control.new()
	_root.name = "TabStrip"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_root.offset_top = 56.0
	_root.offset_bottom = 78.0
	_build_labels()
	_refresh_visual()


func get_active_index() -> int:
	return _active_index


func set_active_tab(index: int) -> void:
	if index < 0 or index >= TAB_NAMES.size():
		return
	if index == _active_index:
		return
	_active_index = index
	_refresh_visual()
	tab_changed.emit(_active_index)


func cycle(direction: int) -> void:
	var next: int = wrapi(_active_index + direction, 0, TAB_NAMES.size())
	set_active_tab(next)


# --- 내부 ---


func _build_labels() -> void:
	var box := HBoxContainer.new()
	box.name = "TabBox"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(TAB_SPACING))
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(box)
	for i in range(TAB_NAMES.size()):
		var lbl := Label.new()
		lbl.name = "Tab_%d" % i
		lbl.text = TAB_NAMES[i]
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_INACTIVE)
		box.add_child(lbl)
		_labels.append(lbl)


func _refresh_visual() -> void:
	for i in range(_labels.size()):
		var lbl: Label = _labels[i]
		if i == _active_index:
			lbl.text = "[ %s ]" % TAB_NAMES[i]
			lbl.add_theme_color_override("font_color", COLOR_ACTIVE)
		else:
			lbl.text = "  %s  " % TAB_NAMES[i]
			lbl.add_theme_color_override("font_color", COLOR_INACTIVE)
