class_name SkillExecutor
extends RefCounted

## 스킬 1건의 실행 본체. SkillSystem.execute()가 위임한다.
## 책임: 자원 체크/소모 → 쿨다운 시작 → effect_type 디스패치 → 애니메이션 → 시그널.
## 슬롯 유효성/쿨다운 체크는 진입점(SkillSystem.execute)에서 수행.

const MeleeHandlerScript = preload("res://src/systems/skill/effect_handlers/skill_handler_melee.gd")
const AoeHandlerScript = preload("res://src/systems/skill/effect_handlers/skill_handler_aoe.gd")
const ProjectileHandlerScript = preload(
	"res://src/systems/skill/effect_handlers/skill_handler_projectile.gd"
)
const BuffHandlerScript = preload("res://src/systems/skill/effect_handlers/skill_handler_buff.gd")
const CustomHandlerScript = preload(
	"res://src/systems/skill/effect_handlers/skill_handler_custom.gd"
)

## effect_type → 애니메이션 name 폴백. skill_<id> 애니메이션을 우선 시도.
const EFFECT_ANIM_FALLBACK := {
	"melee": "slash",
	"aoe": "slash",
	"projectile": "slash",
	"buff": "slash",
	"custom": "slash",
}


## 스킬 실행 본체. 자원 부족 시 false 반환(쿨다운·소모 없음).
## ctx 키: caster(Node), movement(Node|null), sprite(AnimatedSprite2D|null), slot_index(int).
static func execute(skill: SkillData, ctx: Dictionary) -> bool:
	if skill == null:
		return false

	if not _check_and_consume_resource(skill):
		return false

	var slot_index: int = int(ctx.get("slot_index", -1))
	if slot_index >= 0:
		SkillSystem.start_cooldown(slot_index)

	_dispatch(skill, ctx)
	_play_animation(skill, ctx)

	EventBus.skill_used.emit(slot_index, skill.id)
	return true


static func _check_and_consume_resource(skill: SkillData) -> bool:
	if skill.time_cost <= 0.0:
		return true
	var res_data: Dictionary = TimeSystem.get_resource_data()
	if res_data.get("current", 0.0) < skill.time_cost:
		return false
	EventBus.time_resource_consume_flat_requested.emit(skill.time_cost)
	return true


static func _dispatch(skill: SkillData, ctx: Dictionary) -> void:
	match skill.effect_type:
		"melee":
			MeleeHandlerScript.handle(skill, ctx)
		"aoe":
			AoeHandlerScript.handle(skill, ctx)
		"projectile":
			ProjectileHandlerScript.handle(skill, ctx)
		"buff":
			BuffHandlerScript.handle(skill, ctx)
		"custom":
			CustomHandlerScript.handle(skill, ctx)
		_:
			push_warning("SkillExecutor: unknown effect_type '%s'" % skill.effect_type)


static func _play_animation(skill: SkillData, ctx: Dictionary) -> void:
	var sprite: AnimatedSprite2D = ctx.get("sprite")
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim_name := "skill_%s" % skill.id
	if not sprite.sprite_frames.has_animation(anim_name):
		anim_name = EFFECT_ANIM_FALLBACK.get(skill.effect_type, "slash")
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
