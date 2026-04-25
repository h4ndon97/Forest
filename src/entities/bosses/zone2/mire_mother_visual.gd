extends Node2D

## 늪의 어머니(Mire Mother) 보스 교보재 프로그래밍 아트.
## 원점(0,0) = 지면 접지점. 늪에서 솟아오른 진흙 형체 + 위에서 늘어진 덩굴.
## 페이즈 1: 평이한 진흙 + 안개 차폐 / 페이즈 2: 균열에서 빛나는 물줄기 노출.
## ancient_oakheart_visual.gd 패턴 답습 — 나무 → 진흙·물·덩굴 변주, 푸른 늪 톤.

const BODY_WIDTH: float = 56.0
const BODY_HEIGHT: float = 72.0
const SWAMP_SPREAD: float = 44.0
const SWAMP_DEPTH: float = 8.0
const BODY_TOP_WIDTH: float = 36.0
const WEAK_POINT_RADIUS: float = 10.0

const COLOR_MUD := Color(0.220, 0.240, 0.200, 1.0)
const COLOR_MUD_HIGHLIGHT := Color(0.320, 0.340, 0.280, 1.0)
const COLOR_MUD_SHADOW := Color(0.140, 0.160, 0.120, 1.0)
const COLOR_WATER := Color(0.300, 0.450, 0.550, 1.0)
const COLOR_WATER_GLOW := Color(0.550, 0.850, 1.000, 1.0)
const COLOR_VINE := Color(0.180, 0.300, 0.220, 1.0)
const COLOR_VINE_LIGHT := Color(0.300, 0.420, 0.300, 1.0)
const COLOR_CRACK := Color(0.100, 0.120, 0.080, 1.0)
const COLOR_WEAKPOINT_DARK := Color(0.100, 0.180, 0.220, 1.0)
const COLOR_WEAKPOINT_GLOW := Color(0.600, 0.900, 1.000, 1.0)

const RIPPLE_AMPLITUDE: float = 2.0
const RIPPLE_PERIOD: float = 4.5
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
	_draw_swamp_base()
	_draw_body()
	_draw_mud_creases()
	if _phase >= 1:
		_draw_phase2_cracks()
	_draw_vines()
	_draw_water_drops()
	_draw_weak_point()


func configure(body_size: Vector2, weak_point_offset: Vector2) -> void:
	_body_size = body_size
	_weak_point_offset = weak_point_offset
	queue_redraw()


func set_phase(phase_index: int) -> void:
	_phase = phase_index
	queue_redraw()


# --- 드로잉 ---


func _draw_swamp_base() -> void:
	## 지면에 퍼진 진흙 흙더미 (oakheart roots 변주 — 위로 솟지 않고 옆으로 퍼짐)
	var spread_xs: Array[float] = [
		-SWAMP_SPREAD, -SWAMP_SPREAD * 0.5, 0.0, SWAMP_SPREAD * 0.5, SWAMP_SPREAD
	]
	for x in spread_xs:
		var pts := PackedVector2Array(
			[
				Vector2(x - 6.0, 0.0),
				Vector2(x * 0.5 - 4.0, -SWAMP_DEPTH * 0.6),
				Vector2(x * 0.5 + 4.0, -SWAMP_DEPTH * 0.6),
				Vector2(x + 6.0, 0.0),
			]
		)
		draw_colored_polygon(pts, COLOR_MUD_SHADOW)


func _draw_body() -> void:
	## 진흙 본체 — 위로 갈수록 좁아짐 (출렁임)
	var w_bot: float = _body_size.x
	var w_top: float = BODY_TOP_WIDTH
	var h: float = _body_size.y
	var ripple: float = _get_ripple()
	var body := PackedVector2Array(
		[
			Vector2(-w_bot * 0.5, 0.0),
			Vector2(-w_top * 0.5 + ripple, -h),
			Vector2(w_top * 0.5 + ripple, -h),
			Vector2(w_bot * 0.5, 0.0),
		]
	)
	draw_colored_polygon(body, COLOR_MUD)

	var hl := PackedVector2Array(
		[
			Vector2(-w_bot * 0.5, 0.0),
			Vector2(-w_bot * 0.5 + 5.0, 0.0),
			Vector2(-w_top * 0.5 + 5.0 + ripple, -h),
			Vector2(-w_top * 0.5 + ripple, -h),
		]
	)
	draw_colored_polygon(hl, COLOR_MUD_HIGHLIGHT)

	var sh := PackedVector2Array(
		[
			Vector2(w_bot * 0.5 - 5.0, 0.0),
			Vector2(w_bot * 0.5, 0.0),
			Vector2(w_top * 0.5 + ripple, -h),
			Vector2(w_top * 0.5 - 5.0 + ripple, -h),
		]
	)
	draw_colored_polygon(sh, COLOR_MUD_SHADOW)


func _draw_mud_creases() -> void:
	## 표면 진흙 주름 (oakheart bark grooves 변주 — 더 굽이친 곡선)
	var h: float = _body_size.y
	var ripple: float = _get_ripple()
	var creases: Array[float] = [-10.0, 4.0, 14.0]
	for x in creases:
		var top_x: float = x * (BODY_TOP_WIDTH / _body_size.x) + ripple
		var mid_x: float = lerpf(x, top_x, 0.5) + sin(_t * TAU / RIPPLE_PERIOD + x) * 0.8
		var pts := PackedVector2Array(
			[Vector2(x, -4.0), Vector2(mid_x, -h * 0.5), Vector2(top_x, -h + 4.0)]
		)
		draw_polyline(pts, COLOR_MUD_SHADOW, 1.0, false)


func _draw_phase2_cracks() -> void:
	## 페이즈 2: 진흙 균열에서 빛나는 물줄기 노출
	var h: float = _body_size.y
	var ripple: float = _get_ripple()
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / 2.4)
	var crack_ys: Array[float] = [-h * 0.30, -h * 0.55, -h * 0.78]
	for cy in crack_ys:
		var ratio: float = -cy / h
		var half_w: float = lerpf(_body_size.x * 0.5, BODY_TOP_WIDTH * 0.5, ratio)
		var off: float = ripple * ratio
		var pts := PackedVector2Array()
		var segs: int = 6
		for i in range(segs + 1):
			var t: float = float(i) / float(segs)
			var x: float = lerpf(-half_w + 4.0, half_w - 4.0, t)
			var jitter: float = sin(t * PI * 4.0 + cy) * 1.8
			pts.append(Vector2(x + off, cy + jitter))
		draw_polyline(pts, COLOR_CRACK, 2.0, false)
		# 균열 안 빛나는 물 (가로로 가는 띠)
		var glow: Color = COLOR_WATER_GLOW
		glow.a = 0.35 + 0.25 * pulse
		draw_polyline(pts, glow, 1.0, false)

	# 균열 사이 물 spot (반짝)
	var water_spots: Array[Vector2] = [
		Vector2(-12.0, -h * 0.40 + ripple * 0.40),
		Vector2(10.0, -h * 0.62 + ripple * 0.62),
		Vector2(-6.0, -h * 0.85 + ripple * 0.85),
	]
	for p in water_spots:
		draw_circle(p, 3.0, COLOR_WATER)
		var halo: Color = COLOR_WATER_GLOW
		halo.a = 0.4 + 0.3 * pulse
		draw_circle(p, 4.5, halo)


func _draw_vines() -> void:
	## 머리 위에서 늘어지는 늪 덩굴 (oakheart branch_stubs 변주 — 위로 뻗지 않고 늘어짐)
	var h: float = _body_size.y
	var ripple: float = _get_ripple()
	_draw_vine(
		Vector2(-BODY_TOP_WIDTH * 0.5 + ripple, -h + 4.0),
		Vector2(-BODY_TOP_WIDTH * 0.5 - 14.0 + ripple, -h + 18.0),
		4.5
	)
	_draw_vine(
		Vector2(BODY_TOP_WIDTH * 0.5 + ripple, -h + 6.0),
		Vector2(BODY_TOP_WIDTH * 0.5 + 16.0 + ripple, -h + 16.0),
		4.5
	)
	_draw_vine(Vector2(2.0 + ripple, -h - 2.0), Vector2(4.0 + ripple, -h + 12.0), 3.0)


func _draw_vine(base: Vector2, tip: Vector2, width: float) -> void:
	var dir: Vector2 = (tip - base).normalized()
	if dir.length() < 0.01:
		return
	var normal: Vector2 = dir.rotated(PI * 0.5)
	var half_base: Vector2 = normal * width * 0.5
	var half_tip: Vector2 = normal * width * 0.3
	var pts := PackedVector2Array(
		[
			base + half_base,
			tip + half_tip,
			tip - half_tip,
			base - half_base,
		]
	)
	draw_colored_polygon(pts, COLOR_VINE)
	# 잎/싹 끝 작은 점
	draw_circle(tip, width * 0.45, COLOR_VINE_LIGHT)


func _draw_water_drops() -> void:
	## 본체에 맺힌 물방울 (oakheart moss 변주 — 광택 + 청록 톤)
	var clusters: Array[Vector2] = [
		Vector2(-22.0, -8.0),
		Vector2(16.0, -6.0),
		Vector2(-10.0, -3.0),
		Vector2(20.0, -14.0),
		Vector2(-26.0, -16.0),
	]
	for c in clusters:
		draw_circle(c, 2.5, COLOR_WATER)
		draw_circle(c + Vector2(-1, -1), 1.0, COLOR_WATER_GLOW)


func _draw_weak_point() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / WEAKPOINT_PULSE_PERIOD)
	var ripple: float = _get_ripple()
	var ratio: float = -_weak_point_offset.y / max(_body_size.y, 1.0)
	var center: Vector2 = _weak_point_offset + Vector2(ripple * ratio, 0.0)

	# 평소엔 어두운 청록 수정
	draw_circle(center, WEAK_POINT_RADIUS, COLOR_WEAKPOINT_DARK)

	if _phase >= 1:
		# 페이즈 2: 청빛 발광
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


func _get_ripple() -> float:
	return sin(_t * TAU / RIPPLE_PERIOD) * RIPPLE_AMPLITUDE


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
