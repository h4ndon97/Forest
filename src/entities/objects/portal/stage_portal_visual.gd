extends Node2D

## 스테이지 포탈 — 스프라이트 + 하이브리드 모션 훅 (코어 글로우 / 갤럭시 회전 / 파티클).
## PNG 없을 시 단순 플레이스홀더로 fallback.
## portals_checkpoints.md §2 준수.

const PORTAL_WIDTH: float = 48.0
const PORTAL_HEIGHT: float = 75.0

const COLOR_FALLBACK_STONE := Color(0.420, 0.400, 0.376, 1.0)
const COLOR_PORTAL_GLOW := Color(0.949, 0.8, 0.4, 0.35)

# 스프라이트 모드 전용 — 아트의 청록 크리스털에 맞춘 팔레트
const COLOR_SPRITE_GLOW := Color(0.42, 0.85, 1.0, 1.0)
const COLOR_SPRITE_KEYSTONE := Color(0.75, 0.98, 1.0, 1.0)

const GLOW_PERIOD: float = 2.4
const NEAR_LERP_SPEED: float = 3.0
const NEAR_GLOW_BOOST: float = 1.6

# 배경 halo — 은은하게 개구부를 채움
const GLOW_WIDTH: int = 64
const GLOW_HEIGHT: int = 96
const GLOW_ALPHA_BASE: float = 0.40
const GLOW_ALPHA_AMP: float = 0.08
const GLOW_Y_OFFSET: float = 20.0

# 갤럭시 회전 쉐이더 — 개구부 안에서 회전하는 나선팔
const GALAXY_WIDTH: int = 56
const GALAXY_HEIGHT: int = 88
const GALAXY_SHADER_PATH := "res://src/entities/objects/portal/portal_galaxy.gdshader"

# 키스톤 하이라이트 — 아치 상단 청록 블록
const KEYSTONE_WIDTH: int = 24
const KEYSTONE_HEIGHT: int = 20
const KEYSTONE_ALPHA_BASE: float = 0.32
const KEYSTONE_ALPHA_AMP: float = 0.10
const KEYSTONE_PHASE_OFFSET: float = PI * 0.5
const KEYSTONE_Y_OFFSET: float = -38.0

# 부유 파티클 — 개구부 안을 떠다니는 흰 점들
const PARTICLE_COUNT: int = 16
const PARTICLE_RADIUS: float = 22.0
const PARTICLE_LIFETIME: float = 3.6

@export var sprite_path: String = "res://assets/sprites/objects/portal_stage.png"
## PNG 하단 투명 여백 보정 — 이 값만큼 스프라이트를 아래로 당겨 지면에 정렬.
@export var sprite_bottom_pad: float = 18.0

var player_nearby: bool = false

var _t: float = 0.0
var _near_mix: float = 0.0
var _sprite: Sprite2D
var _core_glow: Sprite2D
var _galaxy: Sprite2D
var _galaxy_mat: ShaderMaterial
var _keystone_glow: Sprite2D
var _particles: GPUParticles2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	var target: float = 1.0 if player_nearby else 0.0
	_near_mix = move_toward(_near_mix, target, delta * NEAR_LERP_SPEED)
	if _sprite != null and _sprite.visible:
		_update_core_glow()
	else:
		queue_redraw()


func _update_core_glow() -> void:
	var phase: float = _t * TAU / GLOW_PERIOD
	var near_boost: float = lerpf(1.0, NEAR_GLOW_BOOST, _near_mix)
	if _core_glow != null:
		var core_a: float = GLOW_ALPHA_BASE + GLOW_ALPHA_AMP * sin(phase)
		_core_glow.modulate.a = clampf(core_a * near_boost, 0.0, 1.0)
	if _galaxy_mat != null:
		_galaxy_mat.set_shader_parameter("near_boost", near_boost)
	if _keystone_glow != null:
		var ks_a: float = (
			KEYSTONE_ALPHA_BASE + KEYSTONE_ALPHA_AMP * sin(phase + KEYSTONE_PHASE_OFFSET)
		)
		_keystone_glow.modulate.a = clampf(ks_a * near_boost, 0.0, 1.0)


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	# PNG 부재 시 단순 플레이스홀더 (스톤 벽 + 맥동 글로우)
	draw_rect(
		Rect2(-PORTAL_WIDTH * 0.5, -PORTAL_HEIGHT, PORTAL_WIDTH, PORTAL_HEIGHT),
		COLOR_FALLBACK_STONE,
		true
	)
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / GLOW_PERIOD)
	var intensity: float = lerpf(0.7, 1.0, pulse) * lerpf(1.0, NEAR_GLOW_BOOST, _near_mix)
	var glow: Color = COLOR_PORTAL_GLOW
	glow.a *= intensity
	draw_circle(Vector2(0, -PORTAL_HEIGHT * 0.5), 14.0, glow)


func set_player_nearby(value: bool) -> void:
	player_nearby = value


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "PortalSprite"
	_sprite.texture = tex
	_sprite.centered = true
	# 캔버스 바닥을 Node2D 원점(지면)에 고정 + PNG 하단 여백 보정
	var sprite_y: float = -float(tex.get_height()) * 0.5 + sprite_bottom_pad
	_sprite.position = Vector2(0, sprite_y)
	add_child(_sprite)
	_core_glow = _make_radial_glow(GLOW_WIDTH, GLOW_HEIGHT, COLOR_SPRITE_GLOW, "PortalCoreGlow")
	_core_glow.position = Vector2(0, sprite_y + GLOW_Y_OFFSET)
	add_child(_core_glow)
	_galaxy = _make_galaxy(GALAXY_WIDTH, GALAXY_HEIGHT, COLOR_SPRITE_GLOW)
	_galaxy.position = Vector2(0, sprite_y + GLOW_Y_OFFSET)
	add_child(_galaxy)
	_keystone_glow = _make_radial_glow(
		KEYSTONE_WIDTH, KEYSTONE_HEIGHT, COLOR_SPRITE_KEYSTONE, "PortalKeystoneGlow"
	)
	_keystone_glow.position = Vector2(0, sprite_y + KEYSTONE_Y_OFFSET + GLOW_Y_OFFSET)
	add_child(_keystone_glow)
	_particles = _make_particles()
	_particles.position = Vector2(0, sprite_y + GLOW_Y_OFFSET)
	add_child(_particles)


func _make_particles() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.name = "PortalParticles"
	p.amount = PARTICLE_COUNT
	p.lifetime = PARTICLE_LIFETIME
	p.preprocess = 2.0
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = PARTICLE_RADIUS
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 0.0
	m.orbit_velocity_min = 0.22
	m.orbit_velocity_max = 0.35
	m.radial_accel_min = -2.0
	m.radial_accel_max = 1.0
	m.damping_min = 0.0
	m.damping_max = 0.0
	m.scale_min = 0.6
	m.scale_max = 1.3
	m.color = Color(1.0, 1.0, 1.0, 0.75)
	p.process_material = m
	return p


func _make_galaxy(w: int, h: int, color: Color) -> Sprite2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var spr := Sprite2D.new()
	spr.name = "PortalGalaxy"
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shader := load(GALAXY_SHADER_PATH) as Shader
	if shader != null:
		_galaxy_mat = ShaderMaterial.new()
		_galaxy_mat.shader = shader
		_galaxy_mat.set_shader_parameter("tint", color)
		spr.material = _galaxy_mat
	return spr


func _make_radial_glow(w: int, h: int, color: Color, node_name: String) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.30), Color(1.0, 1.0, 1.0, 0.0)]
	)
	var gtex := GradientTexture2D.new()
	gtex.gradient = gradient
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = w
	gtex.height = h
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture = gtex
	spr.centered = true
	spr.modulate = Color(color.r, color.g, color.b, 0.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	return spr
