extends RefCounted

## custom 타입 스킬 핸들러. SkillData.custom_script(SkillCustomBase 상속) 인스턴스화 후 실행.


static func handle(skill: SkillData, ctx: Dictionary) -> void:
	if skill.custom_script == null:
		push_warning("skill_handler_custom: '%s' has no custom_script" % skill.id)
		return

	var instance: Object = skill.custom_script.new()
	if not (instance is SkillCustomBase):
		push_warning("skill_handler_custom: '%s' custom_script is not SkillCustomBase" % skill.id)
		return

	(instance as SkillCustomBase).execute(skill, ctx)
