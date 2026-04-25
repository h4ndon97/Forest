class_name SkillCustomBase
extends RefCounted

## effect_type == "custom" 스킬의 실행 로직 베이스.
## SkillData.custom_script에 이 클래스를 상속한 .gd를 지정한다.
## SkillExecutor가 new() 후 execute()를 1회 호출하고 인스턴스를 폐기한다.
## ctx 키: caster(Node), movement(Node|null), sprite(AnimatedSprite2D|null), slot_index(int).


func execute(_skill: SkillData, _ctx: Dictionary) -> void:
	push_error("SkillCustomBase.execute() must be overridden")
