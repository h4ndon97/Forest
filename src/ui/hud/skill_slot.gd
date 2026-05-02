class_name SkillSlot
extends Control

## 개별 스킬 슬롯 (32×32, 사각 외부 링 + 원형 이끼 소켓).
## 이끼 배경 + 베이스 링 + 아이콘 + 쿨다운 둘레 스윕 + Ready 플래시 + 사용 플래시를 그린다.
## 자원 부족(time_cost > 보유 시간자원) 시 아이콘에 반투명 빨강 tint 적용.
## ui_design_master.md §A-7 준수.

const SkillIcons = preload("res://src/ui/hud/skill_icons.gd")

const SLOT_SIZE := 32.0
const CENTER := Vector2(16.0, 16.0)

# A-3 외부 UI PNG 드롭인 (파일 없으면 코드 도형 fallback)
const SLOT_FRAME_PNG := "res://assets/ui/hud/hud_skill_slot_frame.png"
const KEYCAP_PNG := "res://assets/ui/hud/hud_skill_keycap.png"

# 슬롯 위 keycap ornament 규격 (글자는 코드 Label, PNG는 베이스만)
const KEYCAP_SIZE := Vector2(16.0, 16.0)
const KEYCAP_GAP := 5.0  # 슬롯 위 여백
const KEYCAP_FONT := preload("res://assets/fonts/galmuri/Galmuri11.ttf")

const RING_THICKNESS := 2.0
const RING_INSET := 1.0  # 슬롯 가장자리에서 1px 인셋 (사각 링 경로)
const RING_RECT := Rect2(1.0, 1.0, 30.0, 30.0)  # 30×30, 경로 (1,1)~(31,31)
const RING_PERIMETER := 120.0  # 4 × 30
const MOSS_RADIUS := 13.0  # 이끼 배경 원 반경 (원형 유지)

# === 팔레트 (ui_design_master.md §A-7) ===
const COLOR_RING_BASE := Color(0.102, 0.078, 0.063, 1.0)  # #1A1410 금속 다크브라운
const COLOR_MOSS := Color(0.290, 0.353, 0.188, 0.85)  # #4A5A30 이끼 녹색
const COLOR_MOSS_SPECKLE_DARK := Color(0.216, 0.263, 0.141, 0.7)
const COLOR_MOSS_SPECKLE_LIGHT := Color(0.420, 0.561, 0.290, 0.6)

const COLOR_ATTR_LIGHT := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66
const COLOR_ATTR_SHADOW := Color(0.545, 0.184, 0.776, 1.0)  # #8B2FC6
const COLOR_ATTR_HYBRID := Color(0.698, 0.541, 0.588, 1.0)  # 금↔보라 중간
const COLOR_ATTR_NEUTRAL := Color(0.541, 0.541, 0.565, 1.0)  # #8A8A90

const COLOR_COOLDOWN_DIM := Color(0.102, 0.078, 0.063, 0.7)
const COLOR_FLASH := Color(1.0, 1.0, 1.0, 1.0)

# 자원 부족 시 아이콘 multiplicative tint (반투명 빨강)
const COLOR_INSUFFICIENT_TINT := Color(1.0, 0.4, 0.4, 0.7)

# 플래시 지속시간
const USED_FLASH_DURATION := 0.15
const READY_FLASH_DURATION := 0.2

var skill_id: String = ""
var skill_path: String = ""
var cooldown_ratio: float = 0.0
var key_label: String = ""
var resource_insufficient: bool = false

var _used_flash_t: float = 0.0
var _ready_flash_t: float = 0.0
var _icon_sprite: Sprite2D  # 외부 아이콘 PNG 사용 시
var _keycap_node: Control  # 슬롯 위 keycap ornament 컨테이너
var _key_label_node: Label
var _frame_tex: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_keycap()
	_load_decoration_textures()


func _load_decoration_textures() -> void:
	if ResourceLoader.exists(SLOT_FRAME_PNG):
		_frame_tex = load(SLOT_FRAME_PNG) as Texture2D


func _process(delta: float) -> void:
	if _used_flash_t > 0.0:
		_used_flash_t = maxf(0.0, _used_flash_t - delta)
	if _ready_flash_t > 0.0:
		_ready_flash_t = maxf(0.0, _ready_flash_t - delta)
	queue_redraw()


func _draw() -> void:
	if _frame_tex != null:
		_draw_frame_png()
	else:
		_draw_moss_background()
	_draw_ring()
	_draw_icon()
	if _used_flash_t > 0.0:
		_draw_used_flash_overlay()


func _draw_frame_png() -> void:
	# PNG가 moss 배경 + 베이스 링 둘 다 담당. 코드는 속성 색 링 오버레이만 추가.
	var top_left: Vector2 = CENTER - _frame_tex.get_size() * 0.5
	draw_texture(_frame_tex, top_left)


# === 퍼블릭 API ===


func set_skill(p_skill_id: String, p_path: String, p_icon_path: String = "") -> void:
	skill_id = p_skill_id
	skill_path = p_path
	_setup_icon_sprite(p_icon_path)
	queue_redraw()


func set_cooldown_ratio(ratio: float) -> void:
	cooldown_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func set_resource_insufficient(value: bool) -> void:
	if resource_insufficient == value:
		return
	resource_insufficient = value
	# Sprite2D 경로: modulate 직접 적용. 캔버스 드로잉 경로는 _draw_icon이 tint를 적용.
	if _icon_sprite != null and skill_id != "":
		_icon_sprite.modulate = COLOR_INSUFFICIENT_TINT if value else Color.WHITE
	queue_redraw()


func set_key_label(label: String) -> void:
	key_label = label
	if _key_label_node:
		_key_label_node.text = label


func trigger_used_flash() -> void:
	_used_flash_t = USED_FLASH_DURATION


func trigger_ready_flash() -> void:
	_ready_flash_t = READY_FLASH_DURATION


# === 드로잉 ===


func _draw_moss_background() -> void:
	draw_circle(CENTER, MOSS_RADIUS, COLOR_MOSS)
	# 이끼 얼룩 (결정적 오프셋, 시드 고정으로 슬롯마다 동일)
	draw_circle(CENTER + Vector2(-4, -3), 1.6, COLOR_MOSS_SPECKLE_DARK)
	draw_circle(CENTER + Vector2(3, 4), 1.4, COLOR_MOSS_SPECKLE_DARK)
	draw_circle(CENTER + Vector2(-2, 5), 1.0, COLOR_MOSS_SPECKLE_LIGHT)
	draw_circle(CENTER + Vector2(5, -2), 1.0, COLOR_MOSS_SPECKLE_LIGHT)


func _draw_ring() -> void:
	# 베이스 사각 링 (PNG 프레임 없을 때만 — PNG가 베이스 링 담당)
	if _frame_tex == null:
		draw_rect(RING_RECT, COLOR_RING_BASE, false, RING_THICKNESS)

	# 동적 인디케이터: 쿨다운 둘레 스윕 + Ready 플래시. Ready 상시 펄스는 미사용.
	if skill_id == "":
		return

	var attr_color: Color = _attribute_color(skill_path)

	if cooldown_ratio > 0.001:
		var progress := 1.0 - cooldown_ratio
		if progress > 0.001:
			_draw_perimeter_progress(progress, attr_color, RING_THICKNESS)
	elif _ready_flash_t > 0.0:
		# 쿨다운 종료 직후 0.2초 플래시
		var ft: float = _ready_flash_t / READY_FLASH_DURATION
		var flash_color := attr_color
		flash_color.a = ft
		draw_rect(RING_RECT, flash_color, false, RING_THICKNESS + 1.5)


# 12시(상단 중앙)에서 시계방향으로 둘레 traverse, progress(0..1)만큼 라인 그림
func _draw_perimeter_progress(progress: float, color: Color, thickness: float) -> void:
	if progress >= 0.999:
		draw_rect(RING_RECT, color, false, thickness)
		return
	var corners: Array[Vector2] = [
		Vector2(16, 1),  # 12시 시작
		Vector2(31, 1),  # 우상단 코너
		Vector2(31, 31),  # 우하단 코너
		Vector2(1, 31),  # 좌하단 코너
		Vector2(1, 1),  # 좌상단 코너
		Vector2(16, 1),  # 12시 종료
	]
	var seg_lengths: Array[float] = [15.0, 30.0, 30.0, 30.0, 15.0]
	var target: float = progress * RING_PERIMETER
	var traveled := 0.0
	for i in range(5):
		var seg_len: float = seg_lengths[i]
		if traveled + seg_len <= target:
			draw_line(corners[i], corners[i + 1], color, thickness)
			traveled += seg_len
		else:
			var remain: float = target - traveled
			var dir: Vector2 = (corners[i + 1] - corners[i]).normalized()
			var end_pt: Vector2 = corners[i] + dir * remain
			draw_line(corners[i], end_pt, color, thickness)
			return


func _draw_icon() -> void:
	# 빈 슬롯은 아무 것도 그리지 않음 (프레임만 노출).
	if skill_id == "":
		return
	# 자원 부족 시 multiplicative 빨강 tint
	var tint: Color = COLOR_INSUFFICIENT_TINT if resource_insufficient else Color.WHITE
	# Sprite2D 경로는 modulate가 set_resource_insufficient에서 직접 적용됨.
	# 캔버스 드로잉 경로는 SkillIcons.draw에 tint 전달.
	if _icon_sprite == null or not _icon_sprite.visible:
		SkillIcons.draw(self, skill_id, CENTER, tint)


func _draw_used_flash_overlay() -> void:
	var ft: float = _used_flash_t / USED_FLASH_DURATION
	var color := COLOR_FLASH
	color.a = ft * 0.6
	draw_circle(CENTER, MOSS_RADIUS, color)


# === 헬퍼 ===


func _attribute_color(path: String) -> Color:
	match path:
		"light":
			return COLOR_ATTR_LIGHT
		"shadow":
			return COLOR_ATTR_SHADOW
		"hybrid":
			return COLOR_ATTR_HYBRID
		_:
			return COLOR_ATTR_NEUTRAL


func _build_keycap() -> void:
	# 슬롯 위 ornament 컨테이너 (PNG 베이스 + Label 문자)
	_keycap_node = Control.new()
	_keycap_node.name = "Keycap"
	_keycap_node.size = KEYCAP_SIZE
	# 슬롯 32 폭의 중앙(x=8)에 16 폭 keycap, 슬롯 위 4px 여백
	_keycap_node.position = Vector2(
		(SLOT_SIZE - KEYCAP_SIZE.x) * 0.5, -(KEYCAP_SIZE.y + KEYCAP_GAP)
	)
	_keycap_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keycap_node)

	# 베이스: PNG 있으면 TextureRect, 없으면 ColorRect 시안 fallback
	if ResourceLoader.exists(KEYCAP_PNG):
		var tex_rect := TextureRect.new()
		tex_rect.name = "KeycapBg"
		tex_rect.texture = load(KEYCAP_PNG) as Texture2D
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_keycap_node.add_child(tex_rect)
	else:
		var bg := ColorRect.new()
		bg.name = "KeycapFallback"
		bg.color = Color(0.165, 0.125, 0.094, 0.92)  # 다크 브라운
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_keycap_node.add_child(bg)

	# 문자 라벨 (코드 렌더 — PNG에는 글자 없음)
	# Galmuri11 native 11px + 검정 1px 아웃라인 (bold 효과, 사이즈 유지하며 두께 강조)
	_key_label_node = Label.new()
	_key_label_node.name = "KeyLabel"
	_key_label_node.text = key_label  # _ready 이전 set_key_label 값을 반영
	_key_label_node.add_theme_font_override("font", KEYCAP_FONT)
	_key_label_node.add_theme_font_size_override("font_size", 11)
	_key_label_node.add_theme_color_override("font_color", Color(0.102, 0.078, 0.063, 1.0))
	_key_label_node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	_key_label_node.add_theme_constant_override("outline_size", 1)
	_key_label_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_key_label_node.offset_top = 1  # 시각 정렬 미세 조정 (전체 1px 아래로)
	_key_label_node.offset_bottom = 1
	_key_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_keycap_node.add_child(_key_label_node)


func _setup_icon_sprite(icon_path: String) -> void:
	if icon_path == "" or not ResourceLoader.exists(icon_path):
		if _icon_sprite:
			_icon_sprite.visible = false
		return
	if _icon_sprite == null:
		_icon_sprite = Sprite2D.new()
		_icon_sprite.name = "IconSprite"
		_icon_sprite.position = CENTER
		_icon_sprite.centered = true
		add_child(_icon_sprite)
	var tex := load(icon_path) as Texture2D
	if tex:
		_icon_sprite.texture = tex
		_icon_sprite.visible = true
		# 현재 자원 부족 상태 즉시 반영
		_icon_sprite.modulate = (COLOR_INSUFFICIENT_TINT if resource_insufficient else Color.WHITE)
