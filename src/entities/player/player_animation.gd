extends Node

## 상태를 애니메이션 이름으로 매핑하고 AnimatedSprite2D를 제어한다.
## 아트 리소스가 있으면 자동 로드, 없으면 Player.tscn의 embedded SpriteFrames 사용(64×64 fallback).
## 가로 스트립 전제 — 프레임 크기는 텍스처 height에서 추론(64/128 자동 수용).
##
## Idle alternation: idle_00 / idle_01 두 변형이 모두 로드되면 IDLE 상태에서 번갈아 재생.
## 다른 모든 애니메이션은 미존재 시 idle_00로 fallback.

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

const SPRITE_DIR := "res://assets/sprites/player/"

## 최종 fallback 이름. 다른 모든 애니메이션이 미존재일 때 이걸로 떨어진다.
const FINAL_FALLBACK := "idle_00"

## 상태 → 애니메이션 이름. IDLE은 _resolve_anim에서 idle_variants 중 현재 인덱스로 분기.
const STATE_ANIM_MAP := {
	StateMachine.State.IDLE: "idle",
	StateMachine.State.RUN: "run",
	StateMachine.State.JUMP: "jump",
	StateMachine.State.FALL: "fall",
	StateMachine.State.DASH: "dash",
	StateMachine.State.LIGHT_DASH: "light_dash",
}

## 리소스 미존재 시 대체 애니메이션. 다단계 체인 허용 — 최종은 FINAL_FALLBACK으로 수렴.
const FALLBACK_MAP := {
	"run": "idle",
	"jump": "idle",
	"fall": "idle",
	"dash": "idle",
	"light_dash": "dash",
}

## Player.tscn에 박혀있는 모든 embedded animation은 placeholder로 간주.
## 새 .aseprite 워크플로우(2026-05-02) 도입 후 64×64 구 placeholder는 모두 fallback 대상.
## 실제 사용 가능한 애니메이션은 DYNAMIC_ANIM_PATHS PNG 파일 로드 결과로만 결정.
const PLACEHOLDER_EMBEDDED := {
	"idle": true,
	"run": true,
	"slash": true,
	"jump": true,
	"fall": true,
	"dash": true,
}

## 동적 로드 대상 (파일 존재 시 기존 애니메이션 덮어쓰기 포함).
## idle_00/idle_01은 두 변형, 나머지는 단일.
const DYNAMIC_ANIM_PATHS := {
	"idle": SPRITE_DIR + "player_idle.png",
	"idle_00": SPRITE_DIR + "player_idle_00.png",
	"idle_01": SPRITE_DIR + "player_idle_01.png",
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
## idle_00/idle_01은 alternation을 위해 non-loop (animation_finished 시그널 필요).
const LOOPING_ANIMS := {
	"idle": true,
	"run": true,
}

const DEFAULT_ANIM_SPEED := 10.0

var _sprite: AnimatedSprite2D
var _loaded_anims: Dictionary = {}

## idle_NN 변형 목록. 정렬된 상태로 보관 — 0번부터 순차 재생 후 wrap.
var _idle_variants: Array[String] = []
var _current_idle_index: int = 0


func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	_mark_embedded_animations_loaded()
	_load_dynamic_animations()
	_register_combo_animations()
	_detect_idle_variants()
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished)
	# Player.tscn autoplay = "idle" 이 embedded placeholder를 즉시 재생하므로,
	# setup 종료 시점에 idle_00로 강제 전환하여 autoplay race를 차단.
	if _idle_variants.size() > 0:
		_sprite.play(_idle_variants[0])


func update(current_state: int, facing_direction: int) -> void:
	# 원본 스프라이트(.aseprite)가 오른쪽을 보고 그려져 있음 → 왼쪽 이동 시에만 flip.
	_sprite.flip_h = (facing_direction < 0)

	# 공격/스킬 애니메이션 재생 중이면 덮어쓰지 않음
	if _sprite.is_playing() and _is_action_anim(_sprite.animation):
		return

	# IDLE 상태에서 idle 변형이 이미 재생 중이면 덮어쓰지 않음 (alternation 유지)
	if current_state == StateMachine.State.IDLE:
		if _is_idle_variant(_sprite.animation) and _sprite.is_playing():
			return

	var anim_name: String = _resolve_anim(STATE_ANIM_MAP.get(current_state, FINAL_FALLBACK))
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)


## FALLBACK_MAP을 따라 최대 4단계 추적 — 첫 번째 로드된 이름을 반환. 최종 fallback은 idle_00.
## "idle" 가상명은 _idle_variants 현재 인덱스로 분기.
func _resolve_anim(anim_name: String) -> String:
	var current: String = anim_name
	for _i in 4:
		# "idle" 가상명: 현재 idle 변형으로 분기
		if current == "idle" and _idle_variants.size() > 0:
			return _idle_variants[_current_idle_index]
		if _loaded_anims.get(current, false):
			return current
		var next: String = FALLBACK_MAP.get(current, FINAL_FALLBACK)
		if next == current:
			break
		current = next
	# 최종 fallback — idle_00 우선, 없으면 첫 idle 변형, 없으면 embedded "idle"
	if _loaded_anims.get(FINAL_FALLBACK, false):
		return FINAL_FALLBACK
	if _idle_variants.size() > 0:
		return _idle_variants[0]
	return "idle"


## DYNAMIC_ANIM_PATHS 로드 후 idle_NN 변형들을 _idle_variants에 정렬 수집.
func _detect_idle_variants() -> void:
	_idle_variants.clear()
	var candidates: Array[String] = []
	for anim_name: String in _loaded_anims.keys():
		if anim_name.begins_with("idle_") and anim_name != "idle":
			candidates.append(anim_name)
	candidates.sort()
	for n in candidates:
		_idle_variants.append(n)
	_current_idle_index = 0


func _is_idle_variant(anim_name: String) -> bool:
	return anim_name in _idle_variants


## 콤보 N타 공격 애니메이션 재생. 외부(player_combo.gd)에서 호출.
## slash_N → slash → 미로드 시 무동작(현재 idle 변형 alternation 유지).
## 기존 sprite_frames.has_animation 직접 체크는 embedded placeholder를 가짜 양성으로 잡아 우회됨.
func play_attack(hit_number: int) -> void:
	var combo_name := "slash_%d" % hit_number
	if _loaded_anims.get(combo_name, false):
		_sprite.play(combo_name)
		return
	if _loaded_anims.get("slash", false):
		_sprite.play("slash")
		return
	# PNG 미로드 — 현재 애니메이션 그대로 유지 (idle alternation이 자연스럽게 진행)


## 스킬 애니메이션 재생. 외부(skill_executor.gd)에서 호출.
## skill_<id> → slash → 미로드 시 무동작.
func play_skill(skill_id: String, _effect_type: String) -> void:
	var skill_anim := "skill_%s" % skill_id
	if _loaded_anims.get(skill_anim, false):
		_sprite.play(skill_anim)
		return
	if _loaded_anims.get("slash", false):
		_sprite.play("slash")
		return
	# PNG 미로드 — 현재 애니메이션 유지


## 강화 이동 후속 공격 애니메이션 재생. 외부(player_follow_up.gd)에서 호출.
## follow_up_<state_tag> → slash_4 → slash → 미로드 시 무동작.
func play_follow_up(state_tag: String) -> void:
	var dedicated := "follow_up_" + state_tag
	if _loaded_anims.get(dedicated, false):
		_sprite.play(dedicated)
		return
	if _loaded_anims.get("slash_4", false):
		_sprite.play("slash_4")
		return
	if _loaded_anims.get("slash", false):
		_sprite.play("slash")
		return
	# PNG 미로드 — 현재 애니메이션 유지


## non-loop인 idle 변형이 끝났을 때 다음 변형으로 swap.
func _on_animation_finished() -> void:
	var current: String = String(_sprite.animation)
	if not _is_idle_variant(current):
		return
	if _idle_variants.size() <= 1:
		# 변형 1개뿐이면 그대로 다시 재생 (loop 효과)
		_sprite.play(current)
		return
	_current_idle_index = (_current_idle_index + 1) % _idle_variants.size()
	_sprite.play(_idle_variants[_current_idle_index])


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
## 단, slash가 PNG로 실제 로드된 경우에만 복제 — embedded placeholder로는 복제하지 않음 (idle_00 fallback 보장).
func _register_combo_animations() -> void:
	if not _loaded_anims.get("slash", false):
		return

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
	return (
		anim_name.begins_with("slash")
		or anim_name.begins_with("skill_")
		or anim_name.begins_with("follow_up_")
	)


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
