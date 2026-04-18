class_name SkillSlot
extends Control

## 개별 스킬 슬롯 (32×32 원형).
## 링 + 이끼 배경 + 아이콘 + 쿨다운 스윕 + 플래시를 그린다.
## ui_design_master.md §A-7 준수.

const SkillIcons = preload("res://src/ui/hud/skill_icons.gd")

const SLOT_SIZE := 32.0
const CENTER := Vector2(16.0, 16.0)

const RING_RADIUS := 15.0          # 링 중심선 (r=14~16에 2px 스트로크)
const RING_THICKNESS := 2.0
const MOSS_RADIUS := 13.0          # 이끼 배경 원 반경

# === 팔레트 (ui_design_master.md §A-7) ===
const COLOR_RING_BASE := Color(0.102, 0.078, 0.063, 1.0)      # #1A1410 금속 다크브라운
const COLOR_MOSS := Color(0.290, 0.353, 0.188, 0.85)          # #4A5A30 이끼 녹색
const COLOR_MOSS_SPECKLE_DARK := Color(0.216, 0.263, 0.141, 0.7)
const COLOR_MOSS_SPECKLE_LIGHT := Color(0.420, 0.561, 0.290, 0.6)

const COLOR_ATTR_LIGHT := Color(0.949, 0.8, 0.4, 1.0)          # #F2CC66
const COLOR_ATTR_SHADOW := Color(0.545, 0.184, 0.776, 1.0)    # #8B2FC6
const COLOR_ATTR_HYBRID := Color(0.698, 0.541, 0.588, 1.0)    # 금↔보라 중간
const COLOR_ATTR_NEUTRAL := Color(0.541, 0.541, 0.565, 1.0)    # #8A8A90

const COLOR_COOLDOWN_DIM := Color(0.102, 0.078, 0.063, 0.7)
const COLOR_FLASH := Color(1.0, 1.0, 1.0, 1.0)

# 링 펄스 진폭/주기 (ready 상태 호흡)
const PULSE_AMPLITUDE := 0.12
const PULSE_PERIOD := 1.8

# 플래시 지속시간
const USED_FLASH_DURATION := 0.15
const READY_FLASH_DURATION := 0.2

var skill_id: String = ""
var skill_path: String = ""
var cooldown_ratio: float = 0.0
var key_label: String = ""

var _pulse_t: float = 0.0
var _used_flash_t: float = 0.0
var _ready_flash_t: float = 0.0
var _icon_sprite: Sprite2D  # 외부 아이콘 PNG 사용 시
var _key_label_node: Label


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_key_label()


func _process(delta: float) -> void:
	_pulse_t += delta
	if _used_flash_t > 0.0:
		_used_flash_t = maxf(0.0, _used_flash_t - delta)
	if _ready_flash_t > 0.0:
		_ready_flash_t = maxf(0.0, _ready_flash_t - delta)
	queue_redraw()


func _draw() -> void:
	_draw_moss_background()
	_draw_ring()
	_draw_icon()
	if _used_flash_t > 0.0:
		_draw_used_flash_overlay()


# === 퍼블릭 API ===


func set_skill(p_skill_id: String, p_path: String, p_icon_path: String = "") -> void:
	skill_id = p_skill_id
	skill_path = p_path
	_setup_icon_sprite(p_icon_path)
	queue_redraw()


func set_cooldown_ratio(ratio: float) -> void:
	cooldown_ratio = clampf(ratio, 0.0, 1.0)
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
	# 베이스 링 (항상 다크브라운)
	draw_arc(CENTER, RING_RADIUS, 0.0, TAU, 40, COLOR_RING_BASE, RING_THICKNESS, false)

	# 속성 링 (ready 상태: 펄스 컬러, cooldown 상태: 시계 스윕)
	if skill_id == "":
		return

	var attr_color: Color = _attribute_color(skill_path)

	if cooldown_ratio > 0.001:
		# 쿨다운: 시계방향으로 회복하는 스윕 아크
		var progress := 1.0 - cooldown_ratio
		var start_a := -PI * 0.5                       # 12시 시작
		var end_a := start_a + progress * TAU          # 시계방향 회복
		if progress > 0.001:
			draw_arc(CENTER, RING_RADIUS, start_a, end_a, 40, attr_color, RING_THICKNESS, false)
	else:
		# Ready: 미세 펄스 (1+sin)/2 진폭 적용
		var pulse: float = 0.5 + 0.5 * sin(_pulse_t * TAU / PULSE_PERIOD)
		var pulsed := attr_color
		pulsed.a = lerpf(1.0 - PULSE_AMPLITUDE, 1.0, pulse)
		draw_arc(CENTER, RING_RADIUS, 0.0, TAU, 40, pulsed, RING_THICKNESS, false)

		# Ready 플래시 오버레이 (쿨다운 종료 직후 0.2초)
		if _ready_flash_t > 0.0:
			var ft: float = _ready_flash_t / READY_FLASH_DURATION
			var flash_color := attr_color
			flash_color.a = ft
			draw_arc(CENTER, RING_RADIUS, 0.0, TAU, 40, flash_color, RING_THICKNESS + 1.5, false)


func _draw_icon() -> void:
	if skill_id == "":
		SkillIcons.draw(self, "", CENTER)
		return
	# 외부 Sprite2D가 연결되어 있으면 해당 sprite가 alpha로 표현됨 (스프라이트는 자식 노드로 렌더)
	# 없으면 프로그래밍 아이콘
	if _icon_sprite == null or not _icon_sprite.visible:
		SkillIcons.draw(self, skill_id, CENTER)


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


func _build_key_label() -> void:
	_key_label_node = Label.new()
	_key_label_node.name = "KeyLabel"
	_key_label_node.theme_type_variation = &"HudLabel"
	_key_label_node.add_theme_font_size_override("font_size", 8)
	_key_label_node.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.9))
	_key_label_node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_key_label_node.add_theme_constant_override("shadow_offset_x", 1)
	_key_label_node.add_theme_constant_override("shadow_offset_y", 1)
	_key_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_key_label_node.position = Vector2(20, 20)
	_key_label_node.size = Vector2(10, 10)
	add_child(_key_label_node)


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
