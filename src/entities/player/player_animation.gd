extends Node

## 상태를 애니메이션 이름으로 매핑하고 AnimatedSprite2D를 제어한다.
## 아트 리소스가 있으면 자동 로드, 없으면 fallback 애니메이션 사용.

const State = preload("res://src/entities/player/player_state_machine.gd").State

const FRAME_SIZE := Vector2(64, 64)

## 상태 → 애니메이션 이름
const STATE_ANIM_MAP := {
	State.IDLE: "idle",
	State.RUN: "run",
	State.JUMP: "jump",
	State.FALL: "fall",
	State.DASH: "dash",
}

## 리소스 미존재 시 대체 애니메이션
const FALLBACK_MAP := {
	"jump": "run",
	"fall": "run",
	"dash": "run",
}

## 동적 로드 대상 (파일 존재 시 자동 등록)
const DYNAMIC_ANIM_PATHS := {
	"jump": "res://assets/sprites/player/player_jump.png",
	"fall": "res://assets/sprites/player/player_fall.png",
	"dash": "res://assets/sprites/player/player_dash.png",
}

var _sprite: AnimatedSprite2D
var _loaded_anims: Dictionary = {}


func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	_loaded_anims["idle"] = true
	_loaded_anims["run"] = true
	_loaded_anims["slash"] = true
	_load_dynamic_animations()
	_register_combo_animations()


func update(current_state: int, facing_direction: int) -> void:
	_sprite.flip_h = (facing_direction > 0)

	# 콤보 공격 애니메이션 재생 중이면 덮어쓰지 않음
	var current_anim: String = _sprite.animation
	if current_anim.begins_with("slash") and _sprite.is_playing():
		return

	var anim_name: String = STATE_ANIM_MAP.get(current_state, "idle")
	if not _loaded_anims.get(anim_name, false):
		anim_name = FALLBACK_MAP.get(anim_name, "idle")

	if _sprite.animation != anim_name:
		_sprite.play(anim_name)


func _load_dynamic_animations() -> void:
	for anim_name: String in DYNAMIC_ANIM_PATHS:
		var path: String = DYNAMIC_ANIM_PATHS[anim_name]
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path)
		if texture:
			_register_animation(anim_name, texture)
			_loaded_anims[anim_name] = true


## 기존 slash 프레임을 slash_1 ~ slash_4로 복제 등록.
## 아트 리소스가 별도로 준비되면 각각 다른 스프라이트로 교체 가능.
func _register_combo_animations() -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if not frames or not frames.has_animation("slash"):
		return

	for i in range(1, 5):
		var combo_name := "slash_%d" % i
		if frames.has_animation(combo_name):
			continue

		frames.add_animation(combo_name)
		frames.set_animation_loop(combo_name, false)
		frames.set_animation_speed(combo_name, frames.get_animation_speed("slash"))

		var frame_count: int = frames.get_frame_count("slash")
		for f in frame_count:
			var tex: Texture2D = frames.get_frame_texture("slash", f)
			var dur: float = frames.get_frame_duration("slash", f)
			frames.add_frame(combo_name, tex, dur)

		_loaded_anims[combo_name] = true


func _register_animation(anim_name: String, texture: Texture2D) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	var frame_count: int = int(texture.get_width() / FRAME_SIZE.x)

	if frames.has_animation(anim_name):
		frames.clear(anim_name)
	else:
		frames.add_animation(anim_name)

	frames.set_animation_loop(anim_name, anim_name != "dash")
	frames.set_animation_speed(anim_name, 10.0)

	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(FRAME_SIZE.x * i, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(anim_name, atlas)
