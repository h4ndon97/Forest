class_name EffectsHitParticle
extends RefCounted

## 피격 파티클 풀 + 발사 헬퍼 (Phase 3-7 Pass 2 ⑤).
## 카테고리별로 GPUParticles2D N개를 미리 만들어 두고 round-robin으로 restart.
## 텍스처 미지정 시 4x4 흰색 ImageTexture fallback — 색은 프로세스 머티리얼의 색 램프로 적용.

const CATEGORY_ORGANIC: StringName = &"organic"
const CATEGORY_MINERAL: StringName = &"mineral"
const CATEGORY_SHADOW: StringName = &"shadow"

const FINISH_RAMP_LIGHT := Color(1.0, 1.0, 1.0, 1.0)
const FINISH_RAMP_SHADOW := Color(0.55, 0.25, 0.75, 1.0)
const FINISH_RAMP_HYBRID := Color(0.95, 0.80, 0.40, 1.0)

var _host: Node
var _presets: EffectsParticlePresetsData
var _pools: Dictionary = {}  # StringName -> Array[GPUParticles2D]
var _cursors: Dictionary = {}  # StringName -> int
var _fallback_texture: ImageTexture


func _init(host: Node, presets: EffectsParticlePresetsData) -> void:
	_host = host
	_presets = presets if presets != null else EffectsParticlePresetsData.new()
	_fallback_texture = _make_fallback_texture()
	_build_pool(CATEGORY_ORGANIC)
	_build_pool(CATEGORY_MINERAL)
	_build_pool(CATEGORY_SHADOW)


func emit(world_pos: Vector2, category: StringName, is_finish: bool) -> void:
	var pool: Array = _pools.get(category, [])
	if pool.is_empty():
		return
	var idx: int = _cursors.get(category, 0)
	var node: GPUParticles2D = pool[idx] as GPUParticles2D
	_cursors[category] = (idx + 1) % pool.size()
	if node == null:
		return
	node.global_position = world_pos
	_apply_finish(node, category, is_finish)
	node.restart()
	node.emitting = true


## 피니시 속성색을 color ramp에 덮어쓴다. 일반 피격이면 preset 기본 램프로 복원.
func apply_finish_color(category: StringName, finish_attribute: String) -> void:
	var pool: Array = _pools.get(category, [])
	var finish_color: Color = _resolve_finish_ramp_color(finish_attribute)
	for any_node in pool:
		var node: GPUParticles2D = any_node as GPUParticles2D
		if node == null:
			continue
		var mat: ParticleProcessMaterial = node.process_material as ParticleProcessMaterial
		if mat == null:
			continue
		mat.color_ramp = _build_ramp(_get_core_color(category), finish_color)


# --- 내부 ---


func _build_pool(category: StringName) -> void:
	var size: int = maxi(_presets.pool_per_category, 1)
	var arr: Array[GPUParticles2D] = []
	for i in range(size):
		arr.append(_build_emitter(category))
	_pools[category] = arr
	_cursors[category] = 0


func _build_emitter(category: StringName) -> GPUParticles2D:
	var node := GPUParticles2D.new()
	node.name = "HitParticle_%s_%d" % [category, _pools.get(category, []).size()]
	node.one_shot = true
	node.emitting = false
	node.explosiveness = 1.0
	node.amount = _get_amount(category)
	node.lifetime = _get_lifetime(category)
	node.texture = _resolve_texture(category)
	node.process_material = _build_material(category)
	_host.add_child(node)
	return node


func _build_material(category: StringName) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 3.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, _get_gravity(category), 0)
	mat.initial_velocity_min = _get_speed_min(category)
	mat.initial_velocity_max = _get_speed_max(category)
	mat.scale_min = _get_scale(category) * 0.8
	mat.scale_max = _get_scale(category) * 1.2
	mat.damping_min = 20.0
	mat.damping_max = 40.0
	mat.color_ramp = _build_ramp(_get_core_color(category), _get_tint_color(category))
	return mat


func _build_ramp(core: Color, tint: Color) -> GradientTexture1D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var fade: Color = Color(tint.r, tint.g, tint.b, 0.0)
	grad.colors = PackedColorArray([core, tint, fade])
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	return tex


func _apply_finish(node: GPUParticles2D, category: StringName, is_finish: bool) -> void:
	var base_amount: int = _get_amount(category)
	var base_speed_max: float = _get_speed_max(category)
	var base_speed_min: float = _get_speed_min(category)
	var mat: ParticleProcessMaterial = node.process_material as ParticleProcessMaterial
	if is_finish:
		node.amount = int(float(base_amount) * _presets.finish_amount_mult)
		if mat != null:
			mat.initial_velocity_min = base_speed_min * _presets.finish_speed_mult
			mat.initial_velocity_max = base_speed_max * _presets.finish_speed_mult
	else:
		node.amount = base_amount
		if mat != null:
			mat.initial_velocity_min = base_speed_min
			mat.initial_velocity_max = base_speed_max


func _resolve_texture(category: StringName) -> Texture2D:
	var path: String = _get_texture_path(category)
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return _fallback_texture


func _make_fallback_texture() -> ImageTexture:
	var img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


func _resolve_finish_ramp_color(attribute: String) -> Color:
	match attribute:
		"light":
			return FINISH_RAMP_LIGHT
		"shadow":
			return FINISH_RAMP_SHADOW
		"hybrid":
			return FINISH_RAMP_HYBRID
		_:
			return FINISH_RAMP_LIGHT


# --- preset accessors (category → value) ---


func _get_core_color(category: StringName) -> Color:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_color_core
		CATEGORY_MINERAL:
			return _presets.mineral_color_core
		_:
			return _presets.shadow_color_core


func _get_tint_color(category: StringName) -> Color:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_color_tint
		CATEGORY_MINERAL:
			return _presets.mineral_color_tint
		_:
			return _presets.shadow_color_tint


func _get_amount(category: StringName) -> int:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_amount
		CATEGORY_MINERAL:
			return _presets.mineral_amount
		_:
			return _presets.shadow_amount


func _get_lifetime(category: StringName) -> float:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_lifetime
		CATEGORY_MINERAL:
			return _presets.mineral_lifetime
		_:
			return _presets.shadow_lifetime


func _get_speed_min(category: StringName) -> float:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_speed_min
		CATEGORY_MINERAL:
			return _presets.mineral_speed_min
		_:
			return _presets.shadow_speed_min


func _get_speed_max(category: StringName) -> float:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_speed_max
		CATEGORY_MINERAL:
			return _presets.mineral_speed_max
		_:
			return _presets.shadow_speed_max


func _get_gravity(category: StringName) -> float:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_gravity
		CATEGORY_MINERAL:
			return _presets.mineral_gravity
		_:
			return _presets.shadow_gravity


func _get_scale(category: StringName) -> float:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_scale
		CATEGORY_MINERAL:
			return _presets.mineral_scale
		_:
			return _presets.shadow_scale


func _get_texture_path(category: StringName) -> String:
	match category:
		CATEGORY_ORGANIC:
			return _presets.organic_texture_path
		CATEGORY_MINERAL:
			return _presets.mineral_texture_path
		_:
			return _presets.shadow_texture_path
