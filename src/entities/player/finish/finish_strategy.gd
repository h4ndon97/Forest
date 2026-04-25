class_name FinishStrategy
extends RefCounted

## 4타 피니시 속성 분기 전략의 추상 베이스.
## 각 속성(light/shadow/hybrid/neutral)별 독립 파일이 static execute(ctx)를 오버라이드한다.
## player_combo가 피니시 발동 시점에 FINISH_STRATEGIES 매핑에서 선택·호출.

## ctx Dictionary 키 상수.
const KEY_PLAYER := "player"  # CharacterBody2D
const KEY_MOVEMENT := "movement"  # facing_direction 접근
const KEY_HEALTH := "health"  # set_invulnerable(duration)
const KEY_DAMAGE := "damage"  # float, CombatSystem.get_combo_damage(max_hits)
const KEY_CONFIG := "config"  # CombatConfigData
const KEY_ATTRIBUTE := "attribute"  # "light"/"shadow"/"hybrid"/"neutral"


static func execute(_ctx: Dictionary) -> void:
	push_error("FinishStrategy.execute() must be overridden")


## 공통 피니시 히트박스 1개를 CombatSystem에 요청하는 헬퍼.
## hitbox_size/hitbox_offset이 Vector2.ZERO이면 config 값 사용.
static func spawn_standard_finish_hitbox(
	ctx: Dictionary,
	hitbox_size: Vector2 = Vector2.ZERO,
	hitbox_offset: Vector2 = Vector2.ZERO,
	active_duration: float = 0.0,
	damage_override: float = -1.0,
) -> Area2D:
	var player: CharacterBody2D = ctx.get(KEY_PLAYER)
	var movement: Node = ctx.get(KEY_MOVEMENT)
	var config: CombatConfigData = ctx.get(KEY_CONFIG)
	if player == null or movement == null or config == null:
		push_warning("FinishStrategy.spawn_standard_finish_hitbox: ctx missing keys")
		return null

	var effective_size: Vector2 = hitbox_size if hitbox_size != Vector2.ZERO else config.hitbox_size
	var effective_offset: Vector2 = (
		hitbox_offset if hitbox_offset != Vector2.ZERO else config.hitbox_offset
	)
	var effective_duration: float = (
		active_duration if active_duration > 0.0 else config.hit_duration
	)
	var damage_value: float = ctx.get(KEY_DAMAGE, 0.0)
	if damage_override >= 0.0:
		damage_value = damage_override

	var spec := AttackSpec.new()
	spec.attacker = player
	spec.source_group = "player_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = effective_size
	spec.hitbox_offset = Vector2(
		absf(effective_offset.x) * movement.facing_direction,
		effective_offset.y,
	)
	spec.active_duration = effective_duration
	spec.damage = damage_value
	spec.is_finish = true
	spec.attribute = ctx.get(KEY_ATTRIBUTE, "neutral")
	spec.tags = PackedStringArray(["combo", "finish", spec.attribute])

	return CombatSystem.request_attack(spec)
