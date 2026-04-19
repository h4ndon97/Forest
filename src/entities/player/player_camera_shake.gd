extends Node

## Phase 3-7 Pass 1 — 카메라 쉐이크 컴포넌트.
## Player.tscn의 Camera2D 자식으로 부착. EventBus.screen_shake_requested를 구독.
## trauma 누적 (0~1) → trauma² 감쇠 → Camera2D.offset 갱신.
## 플레이어가 없는 씬(타이틀 등)에서는 인스턴스 자체가 없으므로 자동 no-op.

const CONFIG_PATH: String = "res://data/effects/effects_config.tres"

var _camera: Camera2D
var _trauma: float = 0.0
var _max_offset_px: float = 4.0
var _decay_per_sec: float = 1.8
var _enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_camera = get_parent() as Camera2D
	if _camera == null:
		push_warning("PlayerCameraShake: 부모가 Camera2D가 아닙니다 — 비활성")
		set_process(false)
		return
	_load_config_values()
	EventBus.screen_shake_requested.connect(_on_shake_requested)


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value and _camera != null:
		_camera.offset = Vector2.ZERO


func _process(delta: float) -> void:
	if not _enabled or _camera == null:
		return
	if _trauma <= 0.0:
		if _camera.offset != Vector2.ZERO:
			_camera.offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - _decay_per_sec * delta, 0.0)
	var t: float = _trauma * _trauma
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _max_offset_px * t


func _on_shake_requested(trauma: float) -> void:
	if not _enabled:
		return
	_trauma = minf(_trauma + trauma, 1.0)


func _load_config_values() -> void:
	if not ResourceLoader.exists(CONFIG_PATH):
		return
	var cfg: EffectsConfigData = load(CONFIG_PATH) as EffectsConfigData
	if cfg == null:
		return
	_max_offset_px = cfg.shake_max_offset_px
	_decay_per_sec = cfg.shake_decay_per_sec
