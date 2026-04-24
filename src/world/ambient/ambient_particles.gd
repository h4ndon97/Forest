extends Node2D

## Phase 3-7 Pass 5 Step 2 — 낮/밤 앰비언트 파티클.
## 낮(is_day=true) = 흰 꽃가루 / 밤 = 녹색 반딧불. EventBus.day_night_changed 구독으로 페이드 전환.
## DayParticles / NightParticles는 씬에서 freezable_particles 그룹 가입
## → 시간 정지 시 speed_scale=0 자동 적용 (Pass 3 Step 3 인프라).
## feedback_particle_initial_values: 수량·속도 50%로 보수적 시작 — 1구역 아트 적용 시 재튜닝.

const FADE_DURATION: float = 1.0

const DAY_COLOR := Color(0.95, 0.95, 0.9, 0.7)
const DAY_AMOUNT: int = 8
const DAY_LIFETIME: float = 8.0
const DAY_VELOCITY_MIN: float = 4.0
const DAY_VELOCITY_MAX: float = 10.0
const DAY_GRAVITY := Vector3(-3.0, 3.0, 0.0)

const NIGHT_COLOR := Color(0.4, 1.0, 0.4, 0.9)
const NIGHT_AMOUNT: int = 6
const NIGHT_LIFETIME: float = 6.0
const NIGHT_VELOCITY_MIN: float = 2.0
const NIGHT_VELOCITY_MAX: float = 6.0
const NIGHT_GRAVITY := Vector3(0.0, 0.0, 0.0)

const EMISSION_BOX := Vector3(320.0, 180.0, 1.0)

var _tween: Tween

@onready var _day: GPUParticles2D = $DayParticles
@onready var _night: GPUParticles2D = $NightParticles


func _ready() -> void:
	_setup_particle(
		_day, DAY_AMOUNT, DAY_LIFETIME, DAY_COLOR, DAY_VELOCITY_MIN, DAY_VELOCITY_MAX, DAY_GRAVITY
	)
	_setup_particle(
		_night,
		NIGHT_AMOUNT,
		NIGHT_LIFETIME,
		NIGHT_COLOR,
		NIGHT_VELOCITY_MIN,
		NIGHT_VELOCITY_MAX,
		NIGHT_GRAVITY
	)
	EventBus.day_night_changed.connect(_on_day_night_changed)
	_apply_initial_state()


func _setup_particle(
	particles: GPUParticles2D,
	amount: int,
	lifetime: float,
	color: Color,
	vel_min: float,
	vel_max: float,
	gravity: Vector3
) -> void:
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.preprocess = lifetime * 0.5
	particles.local_coords = false
	particles.texture = _make_particle_texture(color)
	particles.process_material = _make_particle_material(vel_min, vel_max, gravity)


func _make_particle_texture(color: Color) -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _make_particle_material(
	vel_min: float, vel_max: float, gravity: Vector3
) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = EMISSION_BOX
	mat.direction = Vector3(1.0, 0.0, 0.0)
	mat.spread = 180.0
	mat.initial_velocity_min = vel_min
	mat.initial_velocity_max = vel_max
	mat.gravity = gravity
	mat.scale_min = 0.5
	mat.scale_max = 1.0
	return mat


func _apply_initial_state() -> void:
	var is_day: bool = TimeSystem.is_day()
	_day.emitting = is_day
	_night.emitting = not is_day
	_day.modulate.a = 1.0 if is_day else 0.0
	_night.modulate.a = 0.0 if is_day else 1.0


func _on_day_night_changed(is_day: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_in: GPUParticles2D = _day if is_day else _night
	var target_out: GPUParticles2D = _night if is_day else _day
	target_in.emitting = true
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(target_in, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_property(target_out, "modulate:a", 0.0, FADE_DURATION)
	_tween.chain().tween_callback(_on_fade_complete.bind(target_out))


func _on_fade_complete(out_particles: GPUParticles2D) -> void:
	out_particles.emitting = false
