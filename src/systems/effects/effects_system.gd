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


# === 공개 API: 스크린 플래시 ===


func request_screen_flash(
	color_value: Color = Color(0.0, 0.0, 0.0, 0.0), duration: float = -1.0
) -> void:
	var color_to_use: Color = color_value if color_value.a > 0.0 else _config.flash_default_color
	var dur: float = duration if duration > 0.0 else _config.flash_default_duration
	OverlaySystem.flash_screen(color_to_use, dur)


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
