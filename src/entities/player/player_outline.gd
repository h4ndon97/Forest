extends Node

## 플레이어 외곽선 강조 매니저.
## Selout(sprite-baked 1px)이 base이고, 본 노드는 강조 모먼트(피니시/피격/시간정지 등)에서
## 외곽선을 1~3프레임 토글한다.
## 외곽선 전용 자식 Sprite2D(_outline_sprite)가 매 프레임 AnimatedSprite2D의 frame_texture를
## 미러링하고, outline_2d.gdshader가 외곽 halo만 그려낸다 — hit_flash와 머티리얼 충돌 회피.

const OUTLINE_SHADER: Shader = preload("res://assets/shaders/effects/outline_2d.gdshader")

# 색 프리셋 (속성 매핑 + 위험·강조)
const COLOR_LIGHT: Color = Color(1.0, 0.92, 0.55, 1.0)
const COLOR_SHADOW: Color = Color(0.78, 0.42, 1.0, 1.0)
const COLOR_HYBRID: Color = Color(0.55, 0.95, 0.95, 1.0)
const COLOR_NEUTRAL: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HURT: Color = Color(1.0, 0.3, 0.3, 1.0)

# 펄스 기본 파라미터 (경량 — config 외부화는 Pass 5 정리 시)
const FINISH_PEAK: float = 1.5
const FINISH_DURATION: float = 0.25
const HURT_PEAK: float = 1.0
const HURT_DURATION: float = 0.15

var _source_sprite: AnimatedSprite2D
var _outline_sprite: Sprite2D
var _material: ShaderMaterial
var _tween: Tween


func setup(source: AnimatedSprite2D) -> void:
	_source_sprite = source

	# 외곽선 전용 Sprite2D 노드 생성 (소스의 sibling — z_index로 뒤쪽 배치)
	_outline_sprite = Sprite2D.new()
	_outline_sprite.name = "OutlineLayer"
	_outline_sprite.position = source.position
	_outline_sprite.centered = source.centered
	_outline_sprite.z_index = source.z_index - 1

	_material = ShaderMaterial.new()
	_material.shader = OUTLINE_SHADER
	_material.set_shader_parameter("outline_width", 0.0)
	_material.set_shader_parameter("outline_color", COLOR_NEUTRAL)
	_outline_sprite.material = _material

	source.get_parent().add_child(_outline_sprite)

	# 이벤트 구독 — 강조 모먼트 트리거
	if not EventBus.combo_finished.is_connected(_on_combo_finished):
		EventBus.combo_finished.connect(_on_combo_finished)
	if not EventBus.damage_received.is_connected(_on_damage_received):
		EventBus.damage_received.connect(_on_damage_received)


func _process(_delta: float) -> void:
	if _source_sprite == null or _outline_sprite == null:
		return
	# 매 프레임 텍스처/위치/방향/모듈레이트 미러링
	var frames: SpriteFrames = _source_sprite.sprite_frames
	if frames != null:
		var anim_name: String = String(_source_sprite.animation)
		var frame_idx: int = _source_sprite.frame
		if frames.has_animation(anim_name) and frame_idx < frames.get_frame_count(anim_name):
			var tex: Texture2D = frames.get_frame_texture(anim_name, frame_idx)
			if tex != _outline_sprite.texture:
				_outline_sprite.texture = tex
	_outline_sprite.flip_h = _source_sprite.flip_h
	_outline_sprite.position = _source_sprite.position
	_outline_sprite.modulate = _source_sprite.modulate
	_outline_sprite.visible = _source_sprite.visible


## 외곽선 펄스 — width를 0 → peak → 0으로 단발 Tween. 진행 중인 Tween은 kill 후 재시작.
func pulse(color: Color, duration: float = 0.15, peak_width: float = 1.0) -> void:
	if _material == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_material.set_shader_parameter("outline_color", color)
	var rise: float = duration * 0.3
	var fall: float = duration - rise
	_tween = create_tween()
	_tween.tween_property(_material, "shader_parameter/outline_width", peak_width, rise)
	_tween.tween_property(_material, "shader_parameter/outline_width", 0.0, fall)


func _on_combo_finished(attribute: String) -> void:
	pulse(_attribute_color(attribute), FINISH_DURATION, FINISH_PEAK)


func _on_damage_received(_amount: float) -> void:
	pulse(COLOR_HURT, HURT_DURATION, HURT_PEAK)


func _attribute_color(attribute: String) -> Color:
	match attribute:
		"light":
			return COLOR_LIGHT
		"shadow":
			return COLOR_SHADOW
		"hybrid":
			return COLOR_HYBRID
		_:
			return COLOR_NEUTRAL
