extends Node

## Phase 3-7 Pass 1 — 이펙트 시스템 Autoload 진입점.
## 공개 API:
##   request_hit_flash(target, color?, duration?)
##   request_shake(preset)            request_shake_amount(trauma)
##   request_hitstop(preset)          request_hitstop_duration(duration, scale?)
##   request_screen_flash(color, duration?)
##   request_afterimage(source, count?, interval?, fade?)
##   get_config()
##
## 카메라 쉐이크는 EventBus.screen_shake_requested 시그널을 emit만 한다.
## (PlayerCameraShake 컴포넌트가 구독 — Player 없는 씬에서 자동 no-op)
## 힛플래시·힛스톱·스크린플래시는 헬퍼/OverlaySystem에 직접 위임.

const HitFlashScript = preload("res://src/systems/effects/effects_hit_flash.gd")
const HitstopScript = preload("res://src/systems/effects/effects_hitstop.gd")
const HitParticleScript = preload("res://src/systems/effects/effects_hit_particle.gd")
const TimeStopScript = preload("res://src/systems/effects/effects_time_stop.gd")
const FreezableScript = preload("res://src/systems/effects/effects_freezable.gd")
const AfterimageScript = preload("res://src/systems/effects/effects_afterimage.gd")
const DuskWarningScript = preload("res://src/systems/effects/effects_dusk_warning.gd")
const HpCrackScript = preload("res://src/systems/effects/effects_hp_crack.gd")
const FinishCutinScript = preload("res://src/systems/effects/effects_finish_cutin.gd")
const DebugScript = preload("res://src/systems/effects/effects_debug.gd")
const HIT_FLASH_SHADER: Shader = preload("res://assets/shaders/effects/hit_flash.gdshader")
const CONFIG_PATH: String = "res://data/effects/effects_config.tres"
const PARTICLE_PRESETS_PATH: String = "res://data/effects/particle_presets.tres"

const PRESET_LIGHT: StringName = &"light"
const PRESET_MEDIUM: StringName = &"medium"
const PRESET_HEAVY: StringName = &"heavy"
const PRESET_FINISH: StringName = &"finish"
const PRESET_HIT: StringName = &"hit"
const PRESET_CRITICAL: StringName = &"critical"

const CATEGORY_ORGANIC: StringName = &"organic"
const CATEGORY_MINERAL: StringName = &"mineral"
const CATEGORY_SHADOW: StringName = &"shadow"

var _config: EffectsConfigData
var _hit_flash: EffectsHitFlash
var _hitstop: EffectsHitstop
var _hit_particle: EffectsHitParticle
var _time_stop: EffectsTimeStop
var _freezable: EffectsFreezable
var _afterimage: EffectsAfterimage
var _dusk_warning: EffectsDuskWarning
var _hp_crack: EffectsHpCrack
var _finish_cutin: EffectsFinishCutin


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	_hit_flash = HitFlashScript.new(
		HIT_FLASH_SHADER, _config.flash_attack_ratio, _config.flash_intensity_mult
	)
	_hitstop = HitstopScript.new(get_tree(), _config.hitstop_scale, _config.hitstop_enabled)
	_hit_particle = HitParticleScript.new(self, _load_particle_presets())
	_time_stop = TimeStopScript.new(self, _config)
	_freezable = FreezableScript.new(self)
	_afterimage = AfterimageScript.new(self)
	_dusk_warning = DuskWarningScript.new(self, _config)
	_hp_crack = HpCrackScript.new(self, _config)
	_finish_cutin = FinishCutinScript.new(self, _config)
	# Phase 4-0 #1 Step 6: 고아 시그널 2종 부활 — damage_resolver가 발행하는 신호를 구독해
	# 내부 request_* 로 포워딩. screen_shake_requested는 이미 pass 1에서 연결돼 있고,
	# screen_flash_requested는 #3 속성 피니시에서 emit 예정(이번 Step 미연결).
	EventBus.hit_flash_requested.connect(_on_hit_flash_requested)
	EventBus.hitstop_requested.connect(_on_hitstop_requested)
	if OS.is_debug_build():
		var debug_node: Node = Node.new()
		debug_node.name = "EffectsDebug"
		debug_node.set_script(DebugScript)
		add_child(debug_node)


# === 공개 API: 힛플래시 ===


func request_hit_flash(
	target: CanvasItem, color_value: Color = Color(0.0, 0.0, 0.0, 0.0), duration: float = -1.0
) -> void:
	if _hit_flash == null:
		return
	var color_to_use: Color = color_value if color_value.a > 0.0 else _config.default_flash_color
	var dur: float = duration if duration > 0.0 else _config.default_flash_duration
	_hit_flash.play(self, target, color_to_use, dur)


# === 공개 API: 카메라 쉐이크 ===


func request_shake(preset: StringName = PRESET_MEDIUM) -> void:
	request_shake_amount(_resolve_shake_preset(preset))


func request_shake_amount(trauma: float) -> void:
	if trauma <= 0.0 or _config.shake_intensity_mult <= 0.0:
		return
	var final_trauma: float = trauma * _config.shake_intensity_mult
	EventBus.screen_shake_requested.emit(final_trauma)


# === 공개 API: 힛스톱 ===


func request_hitstop(preset: StringName = PRESET_HIT) -> void:
	request_hitstop_duration(_resolve_hitstop_preset(preset))


func request_hitstop_duration(duration: float, scale_override: float = -1.0) -> void:
	if _hitstop == null:
		return
	_hitstop.apply(duration, scale_override)


## Step 6: damage_resolver가 preset→duration 변환 후 EventBus emit 하기 위한 공개 조회.
func resolve_hitstop_preset_duration(preset: StringName) -> float:
	return _resolve_hitstop_preset(preset)


# === 공개 API: 스크린 플래시 ===


func request_screen_flash(
	color_value: Color = Color(0.0, 0.0, 0.0, 0.0), duration: float = -1.0
) -> void:
	var color_to_use: Color = color_value if color_value.a > 0.0 else _config.flash_default_color
	var dur: float = duration if duration > 0.0 else _config.flash_default_duration
	OverlaySystem.flash_screen(color_to_use, dur)


# === 공개 API: 디졸브 (Pass 5 Step 1) ===


## cover=true: 화면을 디졸브 색으로 덮음(메뉴 진입). false: 걷기(퇴장).
func request_dissolve(duration: float = -1.0, cover: bool = true) -> void:
	var dur: float = duration if duration > 0.0 else _config.dissolve_transition_duration
	OverlaySystem.play_dissolve(dur, cover)


## 메뉴 진입/퇴장 플래시 — cover→reveal 풀 사이클. 기본값(-1)은 config 값 사용.
func request_dissolve_flash(half_duration: float = -1.0) -> void:
	var half: float = (
		half_duration if half_duration > 0.0 else _config.dissolve_flash_half_duration
	)
	OverlaySystem.flash_dissolve(half)


# === 공개 API: 피니시 컷인 (Pass 5 Step 4) ===


## 보스/엘리트 처치 순간 컷인. 0.6s 시퀀스 (zoom + slowmo + bars + burst + flash).
func request_finish_cutin(world_pos: Vector2, attribute: String = "") -> void:
	if _finish_cutin == null:
		return
	_finish_cutin.request(world_pos, attribute)


# === 공개 API: 기타 ===


func get_config() -> EffectsConfigData:
	return _config


# === 공개 API: 파티클 ===


func request_hit_particle(
	world_pos: Vector2, category: StringName, is_finish: bool = false, finish_attribute: String = ""
) -> void:
	if _hit_particle == null:
		return
	if is_finish and finish_attribute != "":
		_hit_particle.apply_finish_color(category, finish_attribute)
	_hit_particle.emit(world_pos, category, is_finish)


## Pass 3 Step 4: Sprite2D/AnimatedSprite2D 잔상 스폰.
## 기본값(-1)이면 config의 time_stop_afterimage_* 값 사용.
func request_afterimage(
	source: Node2D, count: int = -1, interval: float = -1.0, fade: float = -1.0
) -> void:
	if _afterimage == null or source == null:
		return
	var c: int = count if count > 0 else _config.time_stop_afterimage_count
	var i: float = interval if interval >= 0.0 else _config.time_stop_afterimage_interval
	var f: float = fade if fade > 0.0 else _config.time_stop_afterimage_fade
	_afterimage.spawn(source, c, i, f)


## Pass 3 디버그: 시간 정지 연출 Tween 트랜지션 + freezable 그룹 토글.
## TimeSystem 상태는 건드리지 않는다(EventBus emit 없음) — 적 정지/클럭 사이드이펙트 회피.
func debug_toggle_time_stop() -> void:
	if _time_stop == null:
		return
	var next_on: bool = not _time_stop.is_applied()
	_time_stop.apply_transition(next_on)
	if _freezable != null:
		_freezable.apply(next_on)


## Pass 4 디버그: 땅거미 거리 경고 순환 (-1 → 2 → 1 → 0 → -1).
## DuskSpiderSystem 상태는 건드리지 않는다 — EventBus 덮어쓰기 없이 연출만 미리보기.
func debug_cycle_dusk_distance() -> int:
	if _dusk_warning == null:
		return EffectsDuskWarning.DISTANCE_INACTIVE
	return _dusk_warning.debug_cycle_distance()


func resolve_enemy_category(enemy_type: String) -> StringName:
	match enemy_type:
		"tree", "flower":
			return CATEGORY_ORGANIC
		"rock", "pillar", "shard":
			return CATEGORY_MINERAL
		"dusk_spider":
			return CATEGORY_SHADOW
		_:
			if enemy_type != "":
				push_warning(
					"EffectsSystem: unknown enemy_type '%s' → shadow fallback" % enemy_type
				)
			return CATEGORY_SHADOW


func get_finish_color(attribute: String) -> Color:
	# D7-2: 프로젝트 속성 체계 light/shadow/hybrid와 일치
	match attribute:
		"light":
			return _config.finish_color_light
		"shadow":
			return _config.finish_color_shadow
		"hybrid":
			return _config.finish_color_hybrid
		_:
			return _config.default_flash_color


# === 내부 ===


## Step 6: damage_resolver가 EventBus.hit_flash_requested emit → 여기서 수신 후 헬퍼로 포워딩.
func _on_hit_flash_requested(target: CanvasItem, color: Color, duration: float) -> void:
	request_hit_flash(target, color, duration)


## Step 6: damage_resolver가 EventBus.hitstop_requested emit → 여기서 수신 후 헬퍼로 포워딩.
func _on_hitstop_requested(duration: float, scale: float) -> void:
	request_hitstop_duration(duration, scale)


func _load_config() -> void:
	if ResourceLoader.exists(CONFIG_PATH):
		_config = load(CONFIG_PATH) as EffectsConfigData
	if _config == null:
		push_warning("EffectsSystem: config 누락 — 기본값으로 생성")
		_config = EffectsConfigData.new()


func _load_particle_presets() -> EffectsParticlePresetsData:
	if ResourceLoader.exists(PARTICLE_PRESETS_PATH):
		var presets := load(PARTICLE_PRESETS_PATH) as EffectsParticlePresetsData
		if presets != null:
			return presets
	push_warning("EffectsSystem: particle_presets 누락 — 기본값으로 생성")
	return EffectsParticlePresetsData.new()


func _resolve_shake_preset(preset: StringName) -> float:
	match preset:
		PRESET_LIGHT:
			return _config.shake_preset_light
		PRESET_MEDIUM:
			return _config.shake_preset_medium
		PRESET_HEAVY:
			return _config.shake_preset_heavy
		PRESET_FINISH:
			return _config.shake_preset_finish
		_:
			return _config.shake_preset_medium


func _resolve_hitstop_preset(preset: StringName) -> float:
	match preset:
		PRESET_HIT:
			return _config.hitstop_preset_hit
		PRESET_CRITICAL:
			return _config.hitstop_preset_critical
		PRESET_FINISH:
			return _config.hitstop_preset_finish
		_:
			return _config.hitstop_preset_hit
