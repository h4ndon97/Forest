extends Node2D

## 플레이어 등불 컴포넌트.
## PointLight2D로 분위기 조명을 제공하고,
## ShadowSystem에 등불 소스를 등록하여 밤 그림자를 생성한다.

const CONFIG_PATH := "res://data/lantern/lantern_config.tres"

var _config: LanternConfigData
var _light: PointLight2D
var _is_on: bool = false
var _facing_right: bool = true


func _ready() -> void:
	_config = load(CONFIG_PATH) as LanternConfigData
	_create_light()


func toggle() -> void:
	_is_on = not _is_on
	_light.enabled = _is_on

	if _is_on:
		ShadowSystem.register_lantern(_config.max_range)
		ShadowSystem.update_lantern_position(global_position)
	else:
		ShadowSystem.unregister_lantern()

	EventBus.lantern_toggled.emit(_is_on, global_position)


func is_on() -> bool:
	return _is_on


func update_facing(facing_right: bool) -> void:
	_facing_right = facing_right
	_update_light_position()


func update_position() -> void:
	if _is_on:
		ShadowSystem.update_lantern_position(global_position)


# --- 내부 ---

func _create_light() -> void:
	_light = PointLight2D.new()
	_light.name = "LanternLight"
	_light.enabled = false
	_light.energy = _config.light_energy
	_light.color = _config.light_color
	_light.texture_scale = _config.light_texture_scale
	_light.texture = _create_light_texture()
	_update_light_position()
	add_child(_light)


func _update_light_position() -> void:
	if not _light:
		return
	var offset := _config.offset
	if not _facing_right:
		offset.x = -offset.x
	_light.position = offset


func _create_light_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	var radius := 64.0

	for y in range(128):
		for x in range(128):
			var dist := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - dist / radius, 0.0, 1.0)
			# 부드러운 감쇠
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(img)
