class_name OverlayHpCrack
extends TextureRect

## Phase 3-7 Pass 5 Step 1 ① — HP<threshold 구간에서 화면 전체 크랙 오버레이.
## 아트 `hud_hp_crack.png`가 없으면 visible=false로 유지(소음 없는 no-op).

const CRACK_TEX_PATH := "res://assets/ui/hud_hp_crack.png"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(CRACK_TEX_PATH):
		texture = load(CRACK_TEX_PATH) as Texture2D
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = false


func set_alpha(alpha: float) -> void:
	modulate.a = clampf(alpha, 0.0, 1.0)
	visible = modulate.a > 0.0 and texture != null


func clear() -> void:
	modulate.a = 0.0
	visible = false
