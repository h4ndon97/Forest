extends Node2D

## 그림자를 생성하는 오브젝트에 부착하는 컴포넌트.
## 낮: ShadowSystem의 전역 파라미터를 시그널로 수신하여 그림자 갱신.
## 밤+등불 ON: _process에서 per-object 계산으로 그림자 갱신.
## 아트 리소스가 없으면 fallback(ColorRect)으로 동작한다.

@export var shadow_sprite: Sprite2D
@export var base_offset: Vector2 = Vector2(0, 32)
@export var shadow_length_pixels: float = 48.0
@export var fallback_size: Vector2 = Vector2(32, 8)
@export var fallback_color: Color = Color(0, 0, 0, 0.4)
@export var shadow_z_index: int = -1
## true: 발밑 고정, 방향으로 뻗음 (적용). false: 오프셋 이동 (환경 오브젝트용).
@export var anchor_at_base: bool = false

var _fallback_rect: ColorRect
var _using_fallback: bool = false
var _is_night_mode: bool = false
var _shadow_visible: bool = true
var _owner_instance_id: int = 0


func _ready() -> void:
	_owner_instance_id = get_parent().get_instance_id()

	if not shadow_sprite:
		_create_fallback()

	EventBus.shadow_params_changed.connect(_on_shadow_params_changed)
	EventBus.day_night_changed.connect(_on_day_night_changed)

	# 초기 갱신
	_is_night_mode = not ShadowSystem.is_day_mode()
	if _is_night_mode:
		# 밤 시작 시 등불 없으면 그림자 숨김
		if not ShadowSystem.is_lantern_active():
			_hide_shadow()
	else:
		_apply_shadow(
			ShadowSystem.get_shadow_direction(),
			ShadowSystem.get_shadow_sprite_scale(),
			ShadowSystem.get_shadow_base_alpha()
		)

	# 밤 모드가 아닐 때는 _process 비활성
	set_process(_is_night_mode)


func _process(_delta: float) -> void:
	if not _is_night_mode:
		return

	if not ShadowSystem.is_lantern_active():
		if _shadow_visible:
			_hide_shadow()
		return

	var params: Dictionary = ShadowSystem.get_night_shadow_params(global_position)
	if params.is_empty():
		if _shadow_visible:
			_hide_shadow()
		# 범위 밖 적의 강도를 0으로 갱신
		EventBus.shadow_scale_changed.emit(_owner_instance_id, 0.0)
		return

	if not _shadow_visible:
		_show_shadow()

	_apply_shadow(params["direction"], params["sprite_scale"], ShadowSystem.get_shadow_base_alpha())

	# per-object 강도를 발신 (적 강도 연동용)
	EventBus.shadow_scale_changed.emit(_owner_instance_id, params["intensity"])


func _on_shadow_params_changed(direction: Vector2, sprite_scale: float, _intensity: float) -> void:
	if _is_night_mode:
		# 밤에는 전역 시그널 중 sprite_scale=0 (등불 OFF)만 처리
		if sprite_scale <= 0.0:
			_hide_shadow()
		return

	# 낮: 기존 전역 파라미터 적용
	if not _shadow_visible:
		_show_shadow()
	_apply_shadow(direction, sprite_scale, ShadowSystem.get_shadow_base_alpha())


func _on_day_night_changed(is_day: bool) -> void:
	_is_night_mode = not is_day
	set_process(_is_night_mode)

	if _is_night_mode and not ShadowSystem.is_lantern_active():
		_hide_shadow()


func _apply_shadow(direction: Vector2, sprite_scale: float, alpha: float) -> void:
	if _using_fallback:
		var width := fallback_size.x * sprite_scale
		var half_w := width * 0.5

		if anchor_at_base:
			var pos_x := base_offset.x - half_w + direction.x * half_w
			_fallback_rect.position = Vector2(pos_x, base_offset.y)
		else:
			var offset := base_offset + direction * shadow_length_pixels * sprite_scale
			_fallback_rect.position = Vector2(offset.x - half_w, offset.y)

		_fallback_rect.size = Vector2(width, fallback_size.y)
	elif shadow_sprite:
		var offset := base_offset + direction * shadow_length_pixels * sprite_scale
		shadow_sprite.position = offset
		shadow_sprite.scale.x = sprite_scale
		shadow_sprite.modulate.a = alpha


func _hide_shadow() -> void:
	_shadow_visible = false
	if _using_fallback and _fallback_rect:
		_fallback_rect.visible = false
	elif shadow_sprite:
		shadow_sprite.visible = false


func _show_shadow() -> void:
	_shadow_visible = true
	if _using_fallback and _fallback_rect:
		_fallback_rect.visible = true
	elif shadow_sprite:
		shadow_sprite.visible = true


func _create_fallback() -> void:
	_using_fallback = true
	_fallback_rect = ColorRect.new()
	_fallback_rect.color = fallback_color
	_fallback_rect.size = fallback_size
	_fallback_rect.z_index = shadow_z_index
	add_child(_fallback_rect)
