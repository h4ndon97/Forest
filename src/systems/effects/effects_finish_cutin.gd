class_name EffectsFinishCutin
extends RefCounted

## Phase 3-7 Pass 5 Step 4 — 피니시 컷인.
## 보스/엘리트 처치 순간 0.6s 시퀀스: zoom + 슬로우모션 + 블랙바 + 방사형 burst + flash.
## INARI 레퍼런스(Pass 3 Step 4 이월): 코어+할로 2레이어는 기존 hit_particle 피니시 증폭으로 대체.

const FLASH_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const FLASH_DURATION: float = 0.08
const BAR_SLIDE_DURATION: float = 0.15
const BAR_HOLD_DURATION: float = 0.3

var _host: Node
var _config: EffectsConfigData


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config


func request(world_pos: Vector2, attribute: String) -> void:
	_play_zoom()
	_play_bars()
	_play_burst(world_pos, attribute)
	_play_flash()
	_play_slowmo()


func _play_zoom() -> void:
	var cam: Camera2D = _find_player_camera()
	if cam == null:
		return
	var original_zoom: Vector2 = cam.zoom
	var zoom_tween: Tween = _host.get_tree().create_tween()
	zoom_tween.set_ignore_time_scale(true)
	var target: Vector2 = _config.finish_cutin_zoom_target
	var dur: float = _config.finish_cutin_zoom_duration
	zoom_tween.tween_property(cam, "zoom", target, dur).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	zoom_tween.tween_interval(_config.finish_cutin_slowmo_duration)
	zoom_tween.tween_property(cam, "zoom", original_zoom, dur).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)


func _play_bars() -> void:
	OverlaySystem.play_cinematic_bars(
		BAR_SLIDE_DURATION, BAR_HOLD_DURATION, _config.finish_cutin_bar_thickness
	)


func _play_burst(world_pos: Vector2, attribute: String) -> void:
	# 기존 hit_particle 피니시 모드 재사용 (amount×2 + 속성색 ramp).
	# INARI 2레이어 burst 확장은 추후 — 현재는 최소안.
	_host.call("request_hit_particle", world_pos, _host.CATEGORY_SHADOW, true, attribute)


func _play_flash() -> void:
	OverlaySystem.flash_screen(FLASH_COLOR, FLASH_DURATION)


func _play_slowmo() -> void:
	var original_scale: float = Engine.time_scale
	Engine.time_scale = _config.finish_cutin_slowmo_scale
	var tree: SceneTree = _host.get_tree()
	var timer: SceneTreeTimer = tree.create_timer(
		_config.finish_cutin_slowmo_duration, true, false, true
	)
	await timer.timeout
	Engine.time_scale = original_scale


func _find_player_camera() -> Camera2D:
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as Camera2D
