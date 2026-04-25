extends Node

## 플레이어 스킬 입력 컴포넌트.
## 4개 슬롯 입력을 읽어 SkillSystem.execute()로 위임한다.
## Phase 4-0 #2 Step 3: 실행 파이프라인을 SkillSystem/SkillExecutor로 이전.
## 본 컴포넌트는 입력 경로 전담 — 실행 본체는 system-layer에 배치.
## enemies_active 가드는 각 effect_handler 내부에서 처리(스킬 발동 자체는 항상 허용 →
## 애니메이션/쿨다운/자원 소모는 일관, 히트박스 생성만 조건부).
## 사망 시 잔존 스킬 히트는 attack_requests 큐의 active_duration(~0.2s) 만료로 자연 해소.

var _parent: CharacterBody2D


func setup(parent: CharacterBody2D) -> void:
	_parent = parent


func update(input: Node, _enemies_active: bool) -> void:
	if input.skill_1_pressed:
		SkillSystem.execute(0, _parent)
	if input.skill_2_pressed:
		SkillSystem.execute(1, _parent)
	if input.skill_3_pressed:
		SkillSystem.execute(2, _parent)
	if input.skill_4_pressed:
		SkillSystem.execute(3, _parent)
