extends CanvasLayer

## 전투 HUD — 좌상단 클러스터 (속성 오브 + 콤보 도트 + HP 불씨 pip + 상태이상 배지).
## EventBus 시그널만 수신하여 갱신한다.
## ui_design_master.md §A-5/A-6/A-10 / UI_IMPLEMENTATION_PLAN.md §1.1/§2.3.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const MAX_HP_DEFAULT: float = 100.0
const HP_PER_PIP: float = 20.0

# 콤보 도트 색
const DOT_COLOR_EMPTY := Color(0.29, 0.29, 0.31, 1.0)  # #4A4A50
const DOT_COLOR_ACTIVE := Color(0.95, 0.95, 0.95, 1.0)
const DOT_COLOR_FINISH := Color(0.949, 0.8, 0.4, 1.0)  # 금색 피니시

# HP pip 색 (횃불 불씨)
const PIP_COLOR_FULL := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66
const PIP_COLOR_EMPTY := Color(0.29, 0.29, 0.31, 0.6)  # dim

# 속성 오브 색 (A-6)
const ORB_COLOR_NEUTRAL := Color(0.541, 0.541, 0.565, 0.9)  # #8A8A90
const ORB_COLOR_LIGHT := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66
const ORB_COLOR_SHADOW := Color(0.545, 0.184, 0.776, 1.0)  # #8B2FC6
const ORB_COLOR_HYBRID := Color(0.8, 0.5, 0.6, 1.0)  # placeholder (Pass 2: pulse)

# A-10 펄스 (§2.3): STOPPED 호흡 1.0s, 저체력(<20%) 경고 0.8s — A-7/B-5와 리듬 동조
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.05
const LOW_HP_PERIOD: float = 0.8
const LOW_HP_THRESHOLD: float = 0.2
const LOW_HP_TINT := Color(0.9, 0.275, 0.275, 1.0)  # #E64646

# Pass 5 Step 1 ② — 딜레이드 HP pip: 피격 시 잠시 밝기 유지 후 서서히 꺼짐.
const PIP_FADE_DELAY: float = 0.30
const PIP_FADE_DURATION: float = 0.20

var _combo_dots: Array[ColorRect] = []
var _hp_pips: Array[ColorRect] = []
var _pip_fade_tweens: Array[Tween] = []
var _pip_empty: Array[bool] = []
var _max_hp: float = MAX_HP_DEFAULT
var _current_hp: float = MAX_HP_DEFAULT
var _time_state: int = TimeStateMachine.TimeState.STOPPED
var _pulse_t: float = 0.0
var _death_overlay: ColorRect
var _death_label: Label
var _death_tween: Tween
var _clear_tween: Tween
var _recovery_tween: Tween

@onready var combo_orb: ColorRect = $MarginContainer/Cluster/ComboOrb
@onready var combo_dots_container: HBoxContainer = $MarginContainer/Cluster/ComboDots
@onready var hp_pips_container: HBoxContainer = $MarginContainer/Cluster/HpPips


func _ready() -> void:
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.combo_hit_landed.connect(_on_combo_hit_landed)
	EventBus.combo_finished.connect(_on_combo_finished)
	EventBus.combo_resetted.connect(_on_combo_resetted)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.checkpoint_entered.connect(_on_checkpoint_respawned)
	EventBus.full_recovery_requested.connect(_on_full_recovery)
	EventBus.time_state_changed.connect(_on_time_state_changed)

	_collect_children()
	_create_death_overlay()


func _process(delta: float) -> void:
	_pulse_t += delta
	_apply_pip_pulse()


func _collect_children() -> void:
	for child in combo_dots_container.get_children():
		if child is ColorRect:
			_combo_dots.append(child)
	for child in hp_pips_container.get_children():
		if child is ColorRect:
			_hp_pips.append(child)
	_pip_fade_tweens.resize(_hp_pips.size())
	_pip_empty.resize(_hp_pips.size())


func _create_death_overlay() -> void:
	_death_overlay = ColorRect.new()
	_death_overlay.name = "DeathOverlay"
	_death_overlay.color = Color(0, 0, 0, 0)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	add_child(_death_overlay)
	_death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_death_label = Label.new()
	_death_label.name = "DeathLabel"
	_death_label.text = ""
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.add_theme_font_size_override("font_size", 12)
	_death_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 0))
	_death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(_death_label)
	_death_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# === HP pip ===


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_max_hp = max_hp if max_hp > 0.0 else MAX_HP_DEFAULT
	_current_hp = current_hp
	if _recovery_tween and _recovery_tween.is_running():
		return
	_apply_pip_state()


func _apply_pip_state() -> void:
	var filled_count: int = int(ceil(_current_hp / HP_PER_PIP))
	filled_count = clamp(filled_count, 0, _hp_pips.size())
	for i in _hp_pips.size():
		var pip: ColorRect = _hp_pips[i]
		var should_be_filled: bool = i < filled_count
		_kill_pip_tween(i)
		if should_be_filled:
			pip.color = PIP_COLOR_FULL
			pip.modulate = Color.WHITE
			_pip_empty[i] = false
		else:
			if _pip_empty[i]:
				pip.modulate = Color.WHITE
				continue
			pip.color = PIP_COLOR_FULL
			pip.modulate = Color.WHITE
			_start_pip_fadeout(i)
	_apply_pip_pulse()


func _start_pip_fadeout(i: int) -> void:
	var pip: ColorRect = _hp_pips[i]
	var fade: Tween = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_interval(PIP_FADE_DELAY)
	fade.tween_property(pip, "modulate:a", 0.0, PIP_FADE_DURATION)
	fade.tween_callback(_on_pip_fade_complete.bind(i))
	_pip_fade_tweens[i] = fade


func _on_pip_fade_complete(i: int) -> void:
	if i >= _hp_pips.size():
		return
	var pip: ColorRect = _hp_pips[i]
	pip.color = PIP_COLOR_EMPTY
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


# === 콤보 ===


func _on_combo_hit_landed(hit_number: int) -> void:
	if hit_number < 1 or hit_number > _combo_dots.size():
		return
	for i in _combo_dots.size():
		_combo_dots[i].color = DOT_COLOR_ACTIVE if i < hit_number else DOT_COLOR_EMPTY


func _on_combo_finished(attribute: String) -> void:
	for dot in _combo_dots:
		dot.color = DOT_COLOR_FINISH
	combo_orb.color = _orb_color_for(attribute)


func _on_combo_resetted() -> void:
	for dot in _combo_dots:
		dot.color = DOT_COLOR_EMPTY
	combo_orb.color = ORB_COLOR_NEUTRAL


func _orb_color_for(attribute: String) -> Color:
	match attribute:
		"light":
			return ORB_COLOR_LIGHT
		"shadow":
			return ORB_COLOR_SHADOW
		"hybrid":
			return ORB_COLOR_HYBRID
		_:
			return ORB_COLOR_NEUTRAL


# === 사망/리스폰 ===


func _on_player_died() -> void:
	_death_overlay.visible = true
	_death_overlay.color = Color(0, 0, 0, 0)
	_death_label.text = ""

	if _death_tween:
		_death_tween.kill()
	_death_tween = create_tween()

	_death_tween.tween_property(_death_overlay, "color", Color(0, 0, 0, 0.6), 0.5)

	_death_tween.tween_callback(
		func():
			_death_label.text = "..."
			_death_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 0))
	)
	_death_tween.tween_property(
		_death_label, "theme_override_colors/font_color", Color(0.8, 0.2, 0.2, 1.0), 0.3
	)


func _on_player_respawned(_position: Vector2) -> void:
	_clear_death_overlay()


func _on_checkpoint_respawned(_checkpoint_id: String) -> void:
	if not _death_overlay.visible:
		return
	_clear_death_overlay()


func _clear_death_overlay() -> void:
	if _death_tween:
		_death_tween.kill()
	if _clear_tween:
		_clear_tween.kill()

	_clear_tween = create_tween().set_parallel(true)
	_clear_tween.tween_property(_death_overlay, "color", Color(0, 0, 0, 0), 0.3)
	_clear_tween.tween_property(
		_death_label, "theme_override_colors/font_color", Color(0.8, 0.2, 0.2, 0), 0.2
	)
	_clear_tween.chain().tween_callback(
		func():
			_death_overlay.visible = false
			_death_label.text = ""
	)
