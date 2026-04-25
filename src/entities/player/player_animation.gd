extends Node

## 상태를 애니메이션 이름으로 매핑하고 AnimatedSprite2D를 제어한다.
## 아트 리소스가 있으면 자동 로드, 없으면 Player.tscn의 embedded SpriteFrames 사용(64×64 fallback).
## 가로 스트립 전제 — 프레임 크기는 텍스처 height에서 추론(64/128 자동 수용).

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

const SPRITE_DIR := "res://assets/sprites/player/"

## 상태 → 애니메이션 이름
const STATE_ANIM_MAP := {
	StateMachine.State.IDLE: "idle",
	StateMachine.State.RUN: "run",
	StateMachine.State.JUMP: "jump",
	StateMachine.State.FALL: "fall",
	StateMachine.State.DASH: "dash",
	StateMachine.State.LIGHT_DASH: "light_dash",
}

## 리소스 미존재 시 대체 애니메이션. 다단계 체인 허용(light_dash → dash → run).
const FALLBACK_MAP := {
	"jump": "run",
	"fall": "run",
	"dash": "run",
	"light_dash": "dash",
}

## Player.tscn에 placeholder sub_resource로만 박혀있는 애니메이션.
## 실제 파일이 DYNAMIC_ANIM_PATHS로 로드되기 전엔 embedded 프레임이 빈 영역이라 FALLBACK_MAP으로 우회.
const PLACEHOLDER_EMBEDDED := {
	"jump": true,
	"fall": true,
	"dash": true,
}

## 동적 로드 대상 (파일 존재 시 기존 애니메이션 덮어쓰기 포함).
## idle/run/slash는 128×128 리메이크 드롭인 교체용, 나머지는 기존 placeholder 교체용.
const DYNAMIC_ANIM_PATHS := {
	"idle": SPRITE_DIR + "player_idle.png",
	"run": SPRITE_DIR + "player_run.png",
	"slash": SPRITE_DIR + "player_slash.png",
	"slash_1": SPRITE_DIR + "player_slash_1.png",
	"slash_2": SPRITE_DIR + "player_slash_2.png",
	"slash_3": SPRITE_DIR + "player_slash_3.png",
	"slash_4": SPRITE_DIR + "player_slash_4.png",
	"jump": SPRITE_DIR + "player_jump.png",
	"fall": SPRITE_DIR + "player_fall.png",
	"dash": SPRITE_DIR + "player_dash.png",
	"light_dash": SPRITE_DIR + "player_light_dash.png",
}

## 루프 화이트리스트 — 누락된 이름은 non-loop 기본값.
const LOOPING_ANIMS := {
	"idle": true,
	"run": true,
}

const DEFAULT_ANIM_SPEED := 10.0

var _sprite: AnimatedSprite2D
var _loaded_anims: Dictionary = {}


func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	_mark_embedded_animations_loaded()
	_load_dynamic_animations()
	_register_combo_animations()


func update(current_state: int, facing_direction: int) -> void:
	_sprite.flip_h = (facing_direction > 0)

	# 공격/스킬 애니메이션 재생 중이면 덮어쓰지 않음
	if _sprite.is_playing() and _is_action_anim(_sprite.animation):
		return

	var anim_name: String = _resolve_anim(STATE_ANIM_MAP.get(current_state, "idle"))
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)


## FALLBACK_MAP을 따라 최대 3단계 추적 — 첫 번째 로드된 이름을 반환. 최종 fallback은 "idle".
func _resolve_anim(anim_name: String) -> String:
	var current: String = anim_name
	for _i in 3:
		if _loaded_anims.get(current, false):
			return current
		var next: String = FALLBACK_MAP.get(current, "idle")
		if next == current:
			break
		current = next
	return "idle"


## Player.tscn의 SpriteFrames에 미리 박혀 있는 애니메이션을 _loaded_anims에 반영.
## PLACEHOLDER_EMBEDDED는 제외 — 실제 파일 로드 전엔 미로드 취급해서 FALLBACK_MAP이 작동하게 한다.
func _mark_embedded_animations_loaded() -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null:
		return
	for anim_name: StringName in frames.get_animation_names():
		var name_str: String = String(anim_name)
		if PLACEHOLDER_EMBEDDED.get(name_str, false):
			continue
		_loaded_anims[name_str] = true


func _load_dynamic_animations() -> void:
	for anim_name: String in DYNAMIC_ANIM_PATHS:
		var path: String = DYNAMIC_ANIM_PATHS[anim_name]
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path)
		if texture == null:
			continue
		_register_animation(anim_name, texture)
		_loaded_anims[anim_name] = true


## 전용 slash_1~4 파일이 없을 때만 기존 "slash"를 복제 등록(타격별 모션 분리가 없는 초기 상태).
func _register_combo_animations() -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null or not frames.has_animation("slash"):
		return

	for i in range(1, 5):
		var combo_name := "slash_%d" % i
		if _loaded_anims.get(combo_name, false):
			continue

		if frames.has_animation(combo_name):
			frames.clear(combo_name)
		else:
			frames.add_animation(combo_name)
		frames.set_animation_loop(combo_name, false)
		frames.set_animation_speed(combo_name, frames.get_animation_speed("slash"))

		var frame_count: int = frames.get_frame_count("slash")
		for f in frame_count:
			var tex: Texture2D = frames.get_frame_texture("slash", f)
			var dur: float = frames.get_frame_duration("slash", f)
			frames.add_frame(combo_name, tex, dur)

		_loaded_anims[combo_name] = true


func _is_action_anim(anim_name: String) -> bool:
	return anim_name.begins_with("slash") or anim_name.begins_with("skill_")


## 가로 스트립 텍스처를 AtlasTexture로 슬라이스해 등록.
## 프레임은 정사각형 전제 → width = height. frame_count = texture.width / height.
func _register_animation(anim_name: String, texture: Texture2D) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	var frame_size: int = texture.get_height()
	if frame_size <= 0:
		push_warning("player_animation: %s 텍스처 height 0 — 스킵" % anim_name)
		return
	var frame_count: int = int(texture.get_width() / frame_size)
	if frame_count <= 0:
		push_warning(
			(
				"player_animation: %s 프레임 수 0 (width=%d, height=%d)"
				% [anim_name, texture.get_width(), frame_size]
			)
		)
		return

	if frames.has_animation(anim_name):
		frames.clear(anim_name)
	else:
		frames.add_animation(anim_name)

	frames.set_animation_loop(anim_name, LOOPING_ANIMS.get(anim_name, false))
	frames.set_animation_speed(anim_name, DEFAULT_ANIM_SPEED)

	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_size * i, 0, frame_size, frame_size)
		frames.add_frame(anim_name, atlas)
