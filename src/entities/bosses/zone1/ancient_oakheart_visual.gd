extends Node2D

## 거대 고목(AncientOakheart) 보스 교보재 프로그래밍 아트.
## 원점(0,0) = 지면 접지점. 위로 뻗는 나무 구조.
## 페이즈 1: 온전한 고목 / 페이즈 2: 상처·균열·약점 발광.

const BODY_WIDTH: float = 56.0
const BODY_HEIGHT: float = 72.0
const ROOT_SPREAD: float = 40.0
const ROOT_DEPTH: float = 6.0
const TRUNK_TOP_WIDTH: float = 40.0
const WEAK_POINT_RADIUS: float = 10.0

const COLOR_BARK := Color(0.290, 0.180, 0.110, 1.0)
const COLOR_BARK_HIGHLIGHT := Color(0.420, 0.290, 0.190, 1.0)
const COLOR_BARK_SHADOW := Color(0.190, 0.120, 0.070, 1.0)
const COLOR_INNER_WOOD := Color(0.560, 0.400, 0.240, 1.0)
const COLOR_CRACK := Color(0.120, 0.070, 0.040, 1.0)
const COLOR_MOSS := Color(0.270, 0.350, 0.180, 1.0)
const COLOR_MOSS_LIGHT := Color(0.360, 0.470, 0.240, 1.0)
const COLOR_KNOTHOLE := Color(0.120, 0.070, 0.040, 1.0)
const COLOR_WEAKPOINT_GLOW := Color(0.950, 0.780, 0.380, 1.0)

const SWAY_AMPLITUDE: float = 1.5
const SWAY_PERIOD: float = 3.5
const WEAKPOINT_PULSE_PERIOD: float = 1.6

@export var sprite_path: String = ""

var _body_size: Vector2 = Vector2(BODY_WIDTH, BODY_HEIGHT)
var _weak_point_offset: Vector2 = Vector2(0, -56)
var _phase: int = 0
var _t: float = 0.0
var _sprite: Sprite2D
var _boss_id: String = ""


func _ready() -> void:
	_setup_sprite_fallback()
	_resolve_boss_id()
	if not EventBus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		EventBus.boss_phase_changed.connect(_on_boss_phase_changed)


func _process(delta: float) -> void:
	_t += delta
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	_draw_roots()
	_draw_trunk()
	_draw_bark_grooves()
	if _phase >= 1:
		_draw_phase2_damage()
	_draw_branch_stubs()
	_draw_moss()
	_draw_weak_point()


func configure(body_size: Vector2, weak_point_offset: Vector2) -> void:
	_body_size = body_size
	_weak_point_offset = weak_point_offset
	queue_redraw()


func set_phase(phase_index: int) -> void:
	_phase = phase_index
	queue_redraw()


# --- 드로잉 ---


func _draw_roots() -> void:
	var root_xs: Array[float] = [
		-ROOT_SPREAD, -ROOT_SPREAD * 0.5, 0.0, ROOT_SPREAD * 0.5, ROOT_SPREAD
	]
	for x in root_xs:
		var pts := PackedVector2Array(
			[
				Vector2(x - 4.0, 0.0),
				Vector2(x * 0.4 - 3.0, -ROOT_DEPTH * 1.5),
				Vector2(x * 0.4 + 3.0, -ROOT_DEPTH * 1.5),
				Vector2(x + 4.0, 0.0),
			]
		)
		draw_colored_polygon(pts, COLOR_BARK)


func _draw_trunk() -> void:
	var w_bot: float = _body_size.x
	var w_top: float = TRUNK_TOP_WIDTH
	var h: float = _body_size.y
	var sway: float = _get_sway()
	var trunk := PackedVector2Array(
		[
			Vector2(-w_bot * 0.5, 0.0),
			Vector2(-w_top * 0.5 + sway, -h),
			Vector2(w_top * 0.5 + sway, -h),
			Vector2(w_bot * 0.5, 0.0),
		]
	)
	draw_colored_polygon(trunk, COLOR_BARK)

	var hl := PackedVector2Array(
		[
			Vector2(-w_bot * 0.5, 0.0),
			Vector2(-w_bot * 0.5 + 4.0, 0.0),
			Vector2(-w_top * 0.5 + 4.0 + sway, -h),
			Vector2(-w_top * 0.5 + sway, -h),
		]
	)
	draw_colored_polygon(hl, COLOR_BARK_HIGHLIGHT)

	var sh := PackedVector2Array(
		[
			Vector2(w_bot * 0.5 - 4.0, 0.0),
			Vector2(w_bot * 0.5, 0.0),
			Vector2(w_top * 0.5 + sway, -h),
			Vector2(w_top * 0.5 - 4.0 + sway, -h),
		]
	)
	draw_colored_polygon(sh, COLOR_BARK_SHADOW)


func _draw_bark_grooves() -> void:
	var h: float = _body_size.y
	var sway: float = _get_sway()
	var grooves: Array[float] = [-8.0, 2.0, 12.0]
	for x in grooves:
		var top_x: float = x * (TRUNK_TOP_WIDTH / _body_size.x) + sway
		draw_line(Vector2(x, -4.0), Vector2(top_x, -h + 4.0), COLOR_BARK_SHADOW, 1.0)


func _draw_phase2_damage() -> void:
	var h: float = _body_size.y
	var sway: float = _get_sway()
	var crack_ys: Array[float] = [-h * 0.25, -h * 0.5, -h * 0.75]
	for cy in crack_ys:
		var ratio: float = -cy / h
		var half_w: float = lerpf(_body_size.x * 0.5, TRUNK_TOP_WIDTH * 0.5, ratio)
		var off: float = sway * ratio
		var pts := PackedVector2Array()
		var segs: int = 6
		for i in range(segs + 1):
			var t: float = float(i) / float(segs)
			var x: float = lerpf(-half_w + 3.0, half_w - 3.0, t)
			var jitter: float = sin(t * PI * 5.0 + cy) * 1.5
			pts.append(Vector2(x + off, cy + jitter))
		draw_polyline(pts, COLOR_CRACK, 1.5, false)

	var wood_spots: Array[Vector2] = [
		Vector2(-10.0, -h * 0.35 + sway * 0.35),
		Vector2(8.0, -h * 0.6 + sway * 0.6),
		Vector2(-4.0, -h * 0.82 + sway * 0.82),
	]
	for p in wood_spots:
		draw_circle(p, 3.0, COLOR_INNER_WOOD)


func _draw_branch_stubs() -> void:
	var h: float = _body_size.y
	var sway: float = _get_sway()
	_draw_stub(
		Vector2(-TRUNK_TOP_WIDTH * 0.5 + sway, -h + 4.0),
		Vector2(-TRUNK_TOP_WIDTH * 0.5 - 12.0 + sway, -h - 6.0),
		5.0
	)
	_draw_stub(
		Vector2(TRUNK_TOP_WIDTH * 0.5 + sway, -h + 6.0),
		Vector2(TRUNK_TOP_WIDTH * 0.5 + 14.0 + sway, -h - 4.0),
		5.0
	)
	_draw_stub(Vector2(4.0 + sway, -h), Vector2(6.0 + sway, -h - 8.0), 3.5)


func _draw_stub(base: Vector2, tip: Vector2, width: float) -> void:
	var dir: Vector2 = (tip - base).normalized()
	if dir.length() < 0.01:
		return
	var normal: Vector2 = dir.rotated(PI * 0.5)
	var half_base: Vector2 = normal * width * 0.5
	var half_tip: Vector2 = normal * width * 0.35
	var pts := PackedVector2Array(
		[
			base + half_base,
			tip + half_tip,
			tip - half_tip,
			base - half_base,
		]
	)
	draw_colored_polygon(pts, COLOR_BARK)
	draw_circle(tip, width * 0.4, COLOR_INNER_WOOD)


func _draw_moss() -> void:
	var clusters: Array[Vector2] = [
		Vector2(-20.0, -6.0),
		Vector2(14.0, -4.0),
		Vector2(-8.0, -2.0),
		Vector2(22.0, -10.0),
		Vector2(-24.0, -12.0),
	]
	for c in clusters:
		draw_circle(c, 3.0, COLOR_MOSS)
		draw_circle(c + Vector2(-1, -1), 1.5, COLOR_MOSS_LIGHT)


func _draw_weak_point() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / WEAKPOINT_PULSE_PERIOD)
	var sway: float = _get_sway()
	var ratio: float = -_weak_point_offset.y / max(_body_size.y, 1.0)
	var center: Vector2 = _weak_point_offset + Vector2(sway * ratio, 0.0)

	draw_circle(center, WEAK_POINT_RADIUS, COLOR_KNOTHOLE)

	if _phase >= 1:
		var glow: Color = COLOR_WEAKPOINT_GLOW
		glow.a = 0.35 + 0.35 * pulse
		draw_circle(center, WEAK_POINT_RADIUS + 3.0, glow)
		var core: Color = COLOR_WEAKPOINT_GLOW
		core.a = 0.6 + 0.3 * pulse
		draw_circle(center, WEAK_POINT_RADIUS - 4.0, core)


# --- 시그널 ---


func _on_boss_phase_changed(boss_id: String, _from_phase: int, to_phase: int) -> void:
	if boss_id != _boss_id:
		return
	set_phase(to_phase)


# --- 내부 ---


func _get_sway() -> float:
	return sin(_t * TAU / SWAY_PERIOD) * SWAY_AMPLITUDE


func _resolve_boss_id() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var bd: Variant = parent.get("boss_data")
	if bd == null:
		return
	_boss_id = bd.boss_id


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "BossSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)
