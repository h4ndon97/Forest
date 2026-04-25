extends RefCounted

## buff 타입 스킬 핸들러. Phase 4-E BuffSystem 도입 전까지 stub.
## 본 Phase 4-0 #2에서는 스킬 발동 자체(애니/쿨다운/자원 소모)는 SkillExecutor가 처리하고,
## 이 핸들러는 경고만 남긴다.


static func handle(skill: SkillData, _ctx: Dictionary) -> void:
	push_warning(
		"skill_handler_buff: '%s' buff not yet implemented — Phase 4-E BuffSystem 예정" % skill.id
	)
