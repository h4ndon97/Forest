extends Node

## 전투 시스템 Autoload.
## 전투 설정 관리, 데미지 계산, 리스폰 처리, 전투 HUD 로드.
## Phase 4-0 #1 Step 1 확장: AttackSpec/ProjectileSpec/AoeSpec 기반 request_* API 신설.
## Step 1 시점에는 호출자 없음(미사용). Step 2(player_combo)부터 단계적으로 연결.

const CombatCalculatorScript = preload("res://src/systems/combat/combat_calculator.gd")
const HitboxFactoryScript = preload("res://src/systems/combat/hitbox_factory.gd")
const AttackRequestsScript = preload("res://src/systems/combat/attack_requests.gd")

const CONFIG_PATH := "res://data/combat/combat_config.tres"
const HUD_PATH := "res://src/ui/hud/CombatHud.tscn"

var _config: CombatConfigData
var _spawn_point: Vector2 = Vector2.ZERO
var _last_checkpoint_id: String = ""
var _respawn_timer: Timer
var _attack_requests: AttackRequests = null


func _ready() -> void:
	_config = load(CONFIG_PATH) as CombatConfigData

	_respawn_timer = Timer.new()
	_respawn_timer.name = "RespawnTimer"
	_respawn_timer.one_shot = true
	_respawn_timer.wait_time = _config.respawn_delay
	_respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(_respawn_timer)

	_attack_requests = AttackRequestsScript.new()

	EventBus.player_died.connect(_on_player_died)
	EventBus.spawn_point_set.connect(_on_spawn_point_set)
	EventBus.checkpoint_entered.connect(_on_checkpoint_entered)

	_load_hud.call_deferred()


func _process(delta: float) -> void:
	if _attack_requests != null:
		_attack_requests.process(delta)


# === Public API ===


func get_config() -> CombatConfigData:
	return _config


func get_combo_damage(hit_number: int) -> float:
	var base: float = CombatCalculatorScript.calculate_hit_damage(hit_number, _config)
	base += GrowthSystem.get_attack_bonus()
	base += InventorySystem.get_attack_bonus()
	return CombatCalculatorScript.calculate_final_damage(base, _config.finish_attribute)


func set_spawn_point(position: Vector2) -> void:
	_spawn_point = position


func get_spawn_point() -> Vector2:
	return _spawn_point


# === Phase 4-0 #1 Step 1: 공격 요청 API (미사용 상태) ===


## spec의 파라미터로 히트박스(Area2D)를 spec.attacker 자식에 생성하고 생명주기를 등록한다.
## 반환값: 생성된 Area2D — 요청자가 런타임 형상 갱신(HitboxFactory.apply_shape)에 사용 가능.
## telegraph_duration > 0이면 예고 단계부터, 아니면 즉시 active.
func request_attack(spec: AttackSpec) -> Area2D:
	if spec == null:
		push_warning("CombatSystem.request_attack: spec is null")
		return null
	var area: Area2D = HitboxFactoryScript.create_attack_hitbox(spec)
	if area == null:
		return null
	_attack_requests.enqueue(area, spec)
	return area


## 진행 중인 공격 요청을 조기 종료 (예: 공격자 사망, 경직).
func cancel_attack(area: Area2D) -> void:
	if _attack_requests != null:
		_attack_requests.cancel(area)


## 외부(예: 보스 예고선 시각 컴포넌트)가 페이즈 전환 구독용으로 참조.
func get_attack_requests() -> AttackRequests:
	return _attack_requests


## 투사체 씬을 인스턴싱하고 setup()을 호출한다. Step 1 scaffolding — 실제 사용은 Step 4.
func request_projectile(spec: ProjectileSpec) -> Node2D:
	if spec == null or spec.scene == null:
		push_warning("CombatSystem.request_projectile: spec or scene is null")
		return null
	if spec.attacker == null or not is_instance_valid(spec.attacker):
		push_warning("CombatSystem.request_projectile: spec.attacker invalid")
		return null
	var instance: Node = spec.scene.instantiate()
	var projectile: Node2D = instance as Node2D
	if projectile == null:
		instance.queue_free()
		push_warning("CombatSystem.request_projectile: scene root is not Node2D")
		return null
	projectile.global_position = spec.spawn_position
	# setup을 add_child 전에 호출 — _ready의 _update_visual_facing 등이 _velocity를 보고
	# 좌우 flip을 결정하므로 _ready 진입 전에 setup이 끝나야 한다.
	if projectile.has_method("setup"):
		projectile.call("setup", spec.direction, spec.speed, spec.damage, spec.lifetime)
	# 투사체는 공격자가 아닌 공격자의 부모(스테이지)에 부착 — 공격자 사망 시에도 비행 유지.
	var attach_parent: Node = spec.attacker.get_parent()
	if attach_parent == null:
		attach_parent = get_tree().current_scene
	attach_parent.add_child(projectile)
	return projectile


## AoE 공격 — Step 1에서는 stub. #2 SkillExec 또는 #3 속성 피니시(hybrid)에서 구현.
func request_aoe(spec: AoeSpec) -> void:
	if spec == null:
		return
	push_warning("CombatSystem.request_aoe: not yet implemented (Phase 4-0 #2/#3 예정)")


# === 내부 ===


func _on_spawn_point_set(position: Vector2) -> void:
	_spawn_point = position


func _on_checkpoint_entered(checkpoint_id: String) -> void:
	_last_checkpoint_id = checkpoint_id


func _on_player_died() -> void:
	_respawn_timer.start()


func _on_respawn_timeout() -> void:
	if not _last_checkpoint_id.is_empty():
		EventBus.stage_transition_requested.emit(_last_checkpoint_id, "checkpoint")
	else:
		EventBus.player_respawned.emit(_spawn_point)


func _load_hud() -> void:
	if not ResourceLoader.exists(HUD_PATH):
		return
	var hud_scene: PackedScene = load(HUD_PATH)
	if hud_scene:
		var hud := hud_scene.instantiate()
		get_tree().root.add_child(hud)
		hud.add_to_group("game_hud")
