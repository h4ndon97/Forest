extends CanvasLayer

## 전투 HUD — 좌상단 HP 불씨 pip 클러스터.
## EventBus 시그널만 수신하여 갱신한다.
## 콤보 인디케이터는 메모리 [project_combo_indicator_decision.md] 결정으로 제거됨 (2026-04-26).
## ui_design_master.md §A-5/§A-10 / UI_IMPLEMENTATION_PLAN.md §1.1/§2.3.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const MAX_HP_DEFAULT: float = 100.0
const HP_PER_PIP: float = 20.0

# HP pip 색 (횃불 불씨)
const PIP_COLOR_FULL := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66
const PIP_COLOR_EMPTY := Color(0.29, 0.29, 0.31, 0.6)  # dim

# A-10 펄스 (§2.3): STOPPED 호흡 1.0s, 저체력(<20%) 경고 0.8s — A-7/B-5와 리듬 동조
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.05
const LOW_HP_PERIOD: float = 0.8
const LOW_HP_THRESHOLD: float = 0.2
const LOW_HP_TINT := Color(0.9, 0.275, 0.275, 1.0)  # #E64646

# Pass 5 Step 1 ② — 딜레이드 HP pip: 피격 시 잠시 밝기 유지 후 서서히 꺼짐.
const PIP_FADE_DELAY: float = 0.30
const PIP_FADE_DURATION: float = 0.20

# 동적 pip 레이아웃 — max_hp 변동 시 pip 추가/제거.
const PIP_VISUAL_WIDTH: int = 16
const PIP_SEPARATION: int = 2
const FRAME_HORIZONTAL_MARGIN: int = 16  # NinePatch 캡 16px과 정합 — pip이 캡 안쪽 끝에서 시작
const FRAME_HEIGHT: int = 32

# A-1 PNG 드롭인 (파일 없으면 ColorRect/TextureRect fallback).
const HP_PIP_PNG := "res://assets/ui/hud/hud_hp_pip.png"
const TORCH_CORE_PNG := "res://assets/ui/hud/hud_torch_core.png"
const HP_FRAME_PNG := "res://assets/ui/hud/hud_hp_frame.png"

const DeathOverlayScript = preload("res://src/ui/hud/combat_hud_death_overlay.gd")

var _hp_pips: Array[Control] = []
var _pip_fade_tweens: Array[Tween] = []
var _pip_empty: Array[bool] = []
var _max_hp: float = MAX_HP_DEFAULT
var _current_hp: float = MAX_HP_DEFAULT
var _time_state: int = TimeStateMachine.TimeState.STOPPED
var _pulse_t: float = 0.0
var _recovery_tween: Tween
var _has_faded_in: bool = false  # Pass 5 Step 0: HUD 페이드인 1회 가드

@onready var hp_pips_container: HBoxContainer = $MarginContainer/Cluster/HpClusterWrapper/HpPips
@onready var _hp_cluster_wrapper: Control = $MarginContainer/Cluster/HpClusterWrapper
@onready var _torch_frame: TextureRect = $MarginContainer/Cluster/TorchCorePanel/TorchFrame
@onready var _hp_frame: NinePatchRect = $MarginContainer/Cluster/HpClusterWrapper/HpFrame
@onready var _hud_root: MarginContainer = $MarginContainer


func _ready() -> void:
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.full_recovery_requested.connect(_on_full_recovery)
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.stage_entered.connect(_on_first_stage_entered)

	_collect_children()
	add_child(DeathOverlayScript.new())  # 사망 오버레이는 별도 노드가 자체 시그널 처리
	_initialize_visual_state()

	# Pass 5 Step 0: HUD 페이드인 — 첫 stage_entered까지 alpha 0 유지.
	_hud_root.modulate.a = 0.0


func _initialize_visual_state() -> void:
	# 베이스 색을 self_modulate로 즉시 설정 — signal 전에 white 깜빡임 방지.
	for pip in _hp_pips:
		pip.self_modulate = PIP_COLOR_FULL


## 첫 거점 진입 시 1회 페이드인. stage_transition 페이드인 후 짧은 여유 → 0.6s 페이드.
func _on_first_stage_entered(_stage_id: String) -> void:
	if _has_faded_in:
		return
	_has_faded_in = true
	var tween := create_tween()
	tween.tween_interval(OverlaySystem.HUD_FADE_IN_DELAY)
	tween.tween_property(_hud_root, "modulate:a", 1.0, OverlaySystem.HUD_FADE_IN_DURATION)


func _process(delta: float) -> void:
	_pulse_t += delta
	_apply_pip_pulse()


func _collect_children() -> void:
	# 씬의 첫 pip을 텍스처로 교체(있으면), 나머지는 코드가 동적 spawn.
	var existing: Array = hp_pips_container.get_children()
	for i in range(existing.size()):
		var child: Node = existing[i]
		if i == 0 and child is ColorRect:
			_hp_pips.append(_maybe_replace_with_texture(child, HP_PIP_PNG))
		else:
			hp_pips_container.remove_child(child)
			child.queue_free()
	_pip_fade_tweens.resize(_hp_pips.size())
	_pip_empty.resize(_hp_pips.size())
	_load_decoration_textures()
	_resize_hp_cluster()


func _ensure_pip_count(target_count: int) -> void:
	target_count = max(target_count, 1)
	while _hp_pips.size() < target_count:
		_add_pip()
	while _hp_pips.size() > target_count:
		_remove_pip()
	_pip_fade_tweens.resize(_hp_pips.size())
	_pip_empty.resize(_hp_pips.size())
	_resize_hp_cluster()


func _add_pip() -> void:
	if _hp_pips.is_empty():
		return
	var template: Control = _hp_pips[0]
	var new_pip: Control = template.duplicate() as Control
	hp_pips_container.add_child(new_pip)
	_hp_pips.append(new_pip)


func _remove_pip() -> void:
	if _hp_pips.size() <= 1:
		return  # 최소 1개 유지
	var pip: Control = _hp_pips.pop_back()
	hp_pips_container.remove_child(pip)
	pip.queue_free()


func _resize_hp_cluster() -> void:
	if _hp_cluster_wrapper == null:
		return
	var pip_count: int = _hp_pips.size()
	var pips_width: int = pip_count * PIP_VISUAL_WIDTH + max(0, pip_count - 1) * PIP_SEPARATION
	var wrapper_width: int = pips_width + FRAME_HORIZONTAL_MARGIN * 2
	_hp_cluster_wrapper.custom_minimum_size = Vector2(wrapper_width, FRAME_HEIGHT)


func _load_decoration_textures() -> void:
	# 데코레이션 PNG 드롭인. 없으면 TextureRect는 빈 채로 둠 (Label만 보임).
	if ResourceLoader.exists(TORCH_CORE_PNG):
		_torch_frame.texture = load(TORCH_CORE_PNG) as Texture2D
	if ResourceLoader.exists(HP_FRAME_PNG):
		_hp_frame.texture = load(HP_FRAME_PNG) as Texture2D


func _maybe_replace_with_texture(rect: Control, png_path: String) -> Control:
	# PNG 있으면 ColorRect → TextureRect로 교체 (self_modulate/modulate/size 보존).
	if not ResourceLoader.exists(png_path):
		return rect
	var tex: Texture2D = load(png_path) as Texture2D
	if tex == null:
		return rect
	var tex_rect := TextureRect.new()
	tex_rect.name = rect.name
	tex_rect.texture = tex
	tex_rect.custom_minimum_size = rect.custom_minimum_size
	tex_rect.self_modulate = rect.self_modulate
	tex_rect.modulate = rect.modulate
	# PoT 캔버스 + 패딩 호환: cell 크기는 custom_minimum_size 유지, 텍스처는 자연 크기 중앙 정렬.
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var idx: int = rect.get_index()
	var parent: Node = rect.get_parent()
	parent.remove_child(rect)
	rect.queue_free()
	parent.add_child(tex_rect)
	parent.move_child(tex_rect, idx)
	return tex_rect


# === HP pip ===


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_max_hp = max_hp if max_hp > 0.0 else MAX_HP_DEFAULT
	_current_hp = current_hp
	# max_hp 변동 시 pip 개수 동기화 (각 pip = HP_PER_PIP 고정)
	var target_pip_count: int = int(ceil(_max_hp / HP_PER_PIP))
	if target_pip_count != _hp_pips.size():
		_ensure_pip_count(target_pip_count)
	if _recovery_tween and _recovery_tween.is_running():
		return
	_apply_pip_state()


func _apply_pip_state() -> void:
	var filled_count: int = int(ceil(_current_hp / HP_PER_PIP))
	filled_count = clamp(filled_count, 0, _hp_pips.size())
	for i in _hp_pips.size():
		var pip: Control = _hp_pips[i]
		var should_be_filled: bool = i < filled_count
		_kill_pip_tween(i)
		if should_be_filled:
			pip.self_modulate = PIP_COLOR_FULL
			pip.modulate = Color.WHITE
			_pip_empty[i] = false
		else:
			if _pip_empty[i]:
				pip.modulate = Color.WHITE
				continue
			pip.self_modulate = PIP_COLOR_FULL
			pip.modulate = Color.WHITE
			_start_pip_fadeout(i)
	_apply_pip_pulse()


func _start_pip_fadeout(i: int) -> void:
	var pip: Control = _hp_pips[i]
	var fade: Tween = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_interval(PIP_FADE_DELAY)
	fade.tween_property(pip, "modulate:a", 0.0, PIP_FADE_DURATION)
	fade.tween_callback(_on_pip_fade_complete.bind(i))
	_pip_fade_tweens[i] = fade


func _on_pip_fade_complete(i: int) -> void:
	if i >= _hp_pips.size():
		return
	var pip: Control = _hp_pips[i]
	pip.self_modulate = PIP_COLOR_EMPTY
	pip.modulate = Color.WHITE
	_pip_empty[i] = true
	_pip_fade_tweens[i] = null


func _kill_pip_tween(i: int) -> void:
	if i >= _pip_fade_tweens.size():
		return
	var prev: Tween = _pip_fade_tweens[i]
	if prev != null and prev.is_valid():
		prev.kill()
	_pip_fade_tweens[i] = null


func _apply_pip_pulse() -> void:
	# A-10: STOPPED 호흡(채워진 pip alpha ±5%) + 저체력(<20%) 붉은 0.8s 맥동.
	# 저체력 > STOPPED 호흡 > 정상(무처리) 순으로 덮어씀.
	if _hp_pips.is_empty():
		return
	var hp_ratio: float = _current_hp / _max_hp if _max_hp > 0.0 else 0.0
	var is_low: bool = hp_ratio > 0.0 and hp_ratio < LOW_HP_THRESHOLD
	var is_stopped: bool = _time_state == TimeStateMachine.TimeState.STOPPED
	var filled_count: int = int(ceil(_current_hp / HP_PER_PIP))
	filled_count = clamp(filled_count, 0, _hp_pips.size())

	for i in _hp_pips.size():
		# 딜레이드 fade tween이 modulate를 제어 중이면 건드리지 않음.
		if i < _pip_fade_tweens.size() and _pip_fade_tweens[i] != null:
			continue
		var pip := _hp_pips[i]
		if i >= filled_count:
			pip.modulate = Color.WHITE
			continue
		if is_low:
			var k: float = 0.5 + 0.5 * sin(_pulse_t * TAU / LOW_HP_PERIOD)
			pip.modulate = LOW_HP_TINT.lerp(Color.WHITE, 1.0 - k)
		elif is_stopped:
			var breath: float = 0.5 + 0.5 * sin(_pulse_t * TAU / BREATH_PERIOD)
			var a: float = lerpf(1.0 - BREATH_AMPLITUDE, 1.0, breath)
			pip.modulate = Color(1.0, 1.0, 1.0, a)
		else:
			pip.modulate = Color.WHITE


func _on_full_recovery() -> void:
	if _recovery_tween:
		_recovery_tween.kill()
	# Pass 1 placeholder — 즉시 전체 점등. Pass 2에서 순차 점등 애니메이션 추가.
	_current_hp = _max_hp
	_apply_pip_state()


func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	_time_state = new_state
