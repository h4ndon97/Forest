# 시간이 멈춘 숲 — 개발 계획

> 이 문서는 프로토타입부터 Steam 출시까지의 전체 개발 로드맵을 정의한다.
> 1인 개발 체제를 고려하여, 각 단계의 목표와 산출물을 명확히 한다.

---

## 전체 구조

```
Phase 0  기반 세팅                ✅ 완료
Phase 1  코어 프로토타입          ✅ 완료 (1-1~1-7 전체 완료)
Phase 2  시스템 확장
Phase 3  1구역 버티컬 슬라이스
Phase 4  전체 콘텐츠
Phase 5  폴리싱
Phase 6  출시
```

---

## Phase 0 — 기반 세팅 ✅

> 프로젝트 구조, 에이전트, 설계 문서 정비

| 항목 | 상태 |
|---|---|
| 설계 문서 12개 (GDD + 상세) | ✅ |
| CLAUDE.md (아키텍처 원칙) | ✅ |
| 에이전트 7개 | ✅ |
| 프로젝트 폴더 구조 | ✅ |
| project.godot 초기 설정 | ✅ |
| EventBus | ✅ |

---

## Phase 1 — 코어 프로토타입

> **목표**: 핵심 게임 루프 1사이클이 작동하는 최소 플레이 가능 빌드
> **아트**: 전부 플레이스홀더 (단색 사각형, 기본 도형)

### 마일스톤

#### 1-1. 플레이어 기본 이동 ✅
- [x] CharacterBody2D 기반 플레이어 씬
- [x] 달리기 (단일 속도)
- [x] 2단 점프 (코요테 타임, 가변 점프 높이 포함)
- [x] 대시 (쿨다운 기반)
- [x] 카메라 추적
- **의존성**: 없음
- **구현 파일**:
  - `src/entities/player/Player.tscn` — 플레이어 씬 (Composition 패턴, 10개 자식 노드)
  - `src/entities/player/player.gd` — 루트 오케스트레이터
  - `src/entities/player/player_input.gd` — 입력 → 의도 변환
  - `src/entities/player/player_state_machine.gd` — 상태 관리 (IDLE/RUN/JUMP/FALL/DASH)
  - `src/entities/player/player_movement.gd` — 속도 계산
  - `src/entities/player/player_animation.gd` — 상태→애니메이션 매핑
  - `src/entities/player/player_stats_data.gd` — Resource 클래스 (PlayerStatsData)
  - `data/player/player_stats.tres` — 스탯 데이터 인스턴스
- **참고**: 예시 .ase 스프라이트(player_spritesheet.png)로 동작 확인 완료. Jump/Fall/Dash는 임시로 run 애니메이션 사용 중.

#### 1-2. 테스트 스테이지 ✅
- [x] 바닥, 벽, 플랫폼 배치 (StaticBody2D + ColorRect 플레이스홀더)
- [x] 플레이어 스폰 포인트
- [x] 아트 fallback 로직 (PNG 존재 시 자동 적용)
- **의존성**: 1-1
- **구현 파일**:
  - `src/world/stages/TestStage.tscn` — 바닥(640x32), 플랫폼 3개(192x16), 벽 2개, 배경 ColorRect
  - `src/world/stages/test_stage.gd` — 아트 리소스 fallback 로더
- **참고**: TileMap 전환은 Phase 3(1구역 버티컬 슬라이스)에서 타일셋 아트와 함께 진행. 현재 구조는 Phase 1 테스트 목적으로 충분.

#### 1-3. 시간 시스템 ✅
- [x] 시간 상태 머신 (정지 / 조작 / 흐름)
- [x] 시간 조작 (버튼 꾹 → 시각 빠르게 이동)
- [x] 시간 흐름 (1분 = 1시간)
- [x] 시간 자원 소모/회복
- [x] 낮/밤 경계 (06:00, 18:00) 처리
- [x] CanvasModulate 연동 (낮/밤 분위기 전환)
- [x] HUD: 시계 + 시간 자원 게이지
- **의존성**: 1-2
- **구현 파일**:
  - `src/systems/time/time_system.gd` — Autoload 오케스트레이터
  - `src/systems/time/time_state_machine.gd` — 상태 머신 (STOPPED/MANIPULATING/FLOWING)
  - `src/systems/time/time_clock.gd` — 시각 진행, 경계 판정
  - `src/systems/time/time_resource.gd` — 시간 자원 소모/회복
  - `src/systems/time/time_atmosphere.gd` — CanvasModulate 낮/밤 전환
  - `src/systems/time/time_config_data.gd` — Resource 클래스 (TimeConfigData)
  - `data/time/time_config.tres` — 수치 데이터 인스턴스
  - `src/ui/hud/TimeHud.tscn` + `time_hud.gd` — 시간 HUD
- **참고**: 수치(조작 속도, 자원량 등)는 time_config.tres에서 조정. 적 처치 회복은 EventBus 연결 준비 완료.

#### 1-4. 그림자 시스템 ✅
- [x] 오브젝트별 그림자 스프라이트 생성 (ShadowCaster 컴포넌트, fallback ColorRect)
- [x] 시간(태양 각도)에 따른 그림자 방향/길이 변화
- [x] 그림자 scale → 적 강도 배율 매핑 (20%~150%, Curve 슬롯 준비)
- [x] 낮/밤 반전 로직 (밤은 등불 시스템 전까지 fallback 고정값)
- **의존성**: 1-3
- **구현 파일**:
  - `src/systems/shadow/shadow_system.gd` — Autoload 오케스트레이터
  - `src/systems/shadow/shadow_calculator.gd` — 순수 계산 (태양 각도→방향/스케일→강도)
  - `src/systems/shadow/shadow_config_data.gd` — Resource 클래스 (ShadowConfigData)
  - `src/systems/shadow/shadow_caster.gd` — 오브젝트 컴포넌트 (그림자 스프라이트 갱신)
  - `data/shadow/shadow_config.tres` — 수치 데이터 인스턴스
- **참고**: 시스템 간 통신은 EventBus.sun_state_updated 수신 / shadow_params_changed 발신. 매핑 곡선은 선형(기본) + Curve 리소스로 교체 가능. 밤 per-object 계산은 1-7(등불) 구현 시 활성화.

#### 1-5. 적 시스템 (기본) ✅
- [x] 그림자에서 적 생성 (시간 흐름 시) — 현재는 씬 미리 배치 + DORMANT↔활성 전환 방식. 동적 스폰은 Phase 2에서 확장.
- [x] 강도 배율 적용 (HP, 공격력, 속도)
- [x] 기본 AI (순찰, 추적, 공격)
- [x] 베이스 1종 (나무형 — 크고 느림) — 실제로는 4종(나무/바위/꽃/돌기둥) 모두 구현
- [x] 처치 → 그림자 잔류 생성
- **의존성**: 1-4
- **구현 파일**:
  - `src/systems/enemy/enemy_system.gd` — Autoload 오케스트레이터 (활성화/비활성화, 강도 갱신)
  - `src/systems/enemy/enemy_registry.gd` — 적 목록 관리
  - `src/systems/enemy/enemy_intensity.gd` — 전역 강도 → 유형별 배율 변환
  - `src/entities/enemies/base/base_enemy.gd` — 적 루트 스크립트 (Composition 패턴)
  - `src/entities/enemies/base/enemy_state_machine.gd` — AI 상태 머신 (DORMANT/PATROL/CHASE/ATTACK/HURT/DEAD)
  - `src/entities/enemies/base/enemy_stats.gd` — HP/강도 동적 조정
  - `src/entities/enemies/base/enemy_movement.gd` — 이동 계산
  - `src/entities/enemies/base/enemy_animation.gd` — 애니메이션 매핑
  - `src/entities/enemies/shadow_residue/shadow_residue.gd` — 잔류 컴포넌트
  - `data/enemies/enemy_config.tres` — 전역 적 설정
  - `data/enemies/tree_enemy.tres` 등 4종 — 유형별 스탯 데이터

#### 1-6. 기본 전투 ✅
- [x] 4타 횡베기 콤보
- [x] 히트박스/허트박스 시스템
- [x] 데미지 처리 (적 → 플레이어, 플레이어 → 적)
- [x] HP 시스템 (플레이어 + 적)
- [x] 사망 처리 (거점 귀환)
- [x] HUD: HP 게이지
- **의존성**: 1-5
- **구현 파일**:
  - `src/systems/combat/combat_system.gd` — Autoload (리스폰 관리)
  - `src/systems/combat/combat_calculator.gd` — 데미지 계산
  - `src/systems/combat/combat_config_data.gd` — Resource 클래스
  - `data/combat/combat_config.tres` — 전투 수치 데이터
  - `src/entities/player/player_combo.gd` — 4타 콤보 상태 머신 + 동적 히트박스
  - `src/entities/player/player_health.gd` — HP, 넉백, 무적, 사망/리스폰 + 동적 허트박스
  - `src/ui/hud/CombatHud.tscn` + `combat_hud.gd` — HP 바, 콤보 인디케이터, 사망 오버레이

#### 1-7. 등불 (기본) ✅
- [x] PointLight2D 기반 등불
- [x] 밤에 오브젝트에 빛 → 그림자 생성
- [x] 등불 거리 기반 그림자 크기 (밤 반전 로직)
- **의존성**: 1-4
- **구현 파일**:
  - `src/entities/player/player_lantern.gd` — 등불 컴포넌트 (PointLight2D 관리, 토글, EventBus.lantern_toggled 시그널 방송)
  - `data/lantern/lantern_config_data.gd` — Resource 클래스 (LanternConfigData)
  - `data/lantern/lantern_config.tres` — 수치 데이터 인스턴스
- **수정 파일**: shadow_system.gd (등불 관리 API + per-object 계산), shadow_caster.gd (밤 모드 분기 + 폴링), player.gd/player_input.gd/Player.tscn (Lantern 연동), enemy_system.gd/enemy_registry.gd (per-enemy 강도)
- **참고**: 등불 ON/OFF는 L키. 밤+등불 ON 시 ShadowCaster가 per-object로 등불 거리 기반 그림자 계산. 밤+등불 OFF 시 그림자 없음(적 없음). 시간 정지 중에도 토글 가능.

### Phase 1 완료 기준
```
테스트 스테이지 진입
  → 시간 정지 상태에서 시각 확인
  → 시간 조작으로 원하는 시각 설정 (자원 소모)
  → 시간 흐름 → 그림자 변화 → 적 등장
  → 전투 (4타 콤보로 적 처치)
  → 밤 전환 → 등불로 그림자 생성 → 전투
  → 시간 자원 고갈 체험
```

---

## Phase 2 — 시스템 확장

> **목표**: 모든 게임 시스템이 기본 형태로 작동
> **아트**: 플레이스홀더 유지, 플레이어만 기본 애니메이션 적용 가능

### 마일스톤

#### 2-1. 전투 확장 ✅
- [x] 4타 피니시 속성 공격 (빛/그림자/혼합) — SkillSystem.get_finish_attribute() 연동
- [x] 스킬 슬롯 시스템 (4슬롯, 쿨타임) — SkillSystem + SlotManager + HUD
- [x] 스킬 2개 구현 (빛 베기, 그림자 강타) — SkillData Resource + .tres
- [x] 피격 무적 프레임 — Phase 1-6에서 이미 구현 (0.5s i-frames)
- [x] 자동 회복 (시간 정지 상태) — STOPPED 상태에서 auto_heal_timer
- [x] 속성 데미지 배율 프레임워크 — CombatCalculator ATTRIBUTE_MULTIPLIERS (전부 1.0)
- [x] 시간 자원 flat 소비 — consume_flat + EventBus 핸들러
- **의존성**: Phase 1 완료
- **구현 파일**:
  - `data/skills/skill_data.gd` — SkillData Resource 클래스 (class_name)
  - `data/skills/light_slash.tres` — 테스트 스킬: 빛 베기
  - `data/skills/shadow_strike.tres` — 테스트 스킬: 그림자 강타
  - `src/systems/skill/skill_system.gd` — Autoload 오케스트레이터
  - `src/systems/skill/skill_slot_manager.gd` — 4슬롯 장착/쿨다운
  - `src/systems/skill/skill_attribute_resolver.gd` — 피니시 속성 결정
  - `src/entities/player/player_skill.gd` — 플레이어 스킬 입력/실행 컴포넌트
  - `src/ui/hud/SkillHud.tscn` + `skill_hud.gd` — 스킬 슬롯 HUD
- **수정 파일**:
  - `src/systems/event_bus/event_bus.gd` — +스킬/시간자원 시그널 7개
  - `src/entities/player/player_input.gd` — +skill_1~4 입력
  - `src/entities/player/player.gd` — +Skill 컴포넌트 통합
  - `src/entities/player/Player.tscn` — +Skill 자식 노드
  - `src/entities/player/player_combo.gd` — SkillSystem 속성 읽기
  - `src/entities/player/player_health.gd` — +자동 회복 (STOPPED 상태)
  - `src/systems/combat/combat_calculator.gd` — +속성 배율 테이블
  - `src/systems/combat/combat_config_data.gd` — +auto_heal 필드
  - `data/combat/combat_config.tres` — +auto_heal 값
  - `src/systems/time/time_system.gd` — +consume_flat 핸들러
  - `src/systems/time/time_resource.gd` — +consume_flat() 메서드
  - `project.godot` — +SkillSystem Autoload

#### 2-2. 적 확장 ✅
- [x] 베이스 4종 행동 차별화 (나무 범위/바위 방어/돌기둥 원거리/꽃 분열)
- [x] 유형별 그림자 반응 (표준/둔감/민감) — min_intensity로 이미 Phase 1-5에 반영
- [x] 잔류 부활 (HP 50%, 공격력 150%) — Phase 2-3a에서 완료
- **의존성**: Phase 1 완료
- **구현 파일** (2-2a 행동 훅 프레임워크):
  - `src/entities/enemies/base/behaviors/attack_behavior_base.gd` — 공격 행동 베이스 인터페이스
  - `src/entities/enemies/base/behaviors/attack_behavior_melee.gd` — 근접 (hitbox shape 파라미터화 + 활성 지속)
  - `src/entities/enemies/base/behaviors/attack_behavior_none.gd` — 공격 없는 적 (분열체 부활 등)
  - `src/entities/enemies/base/behaviors/death_behavior_base.gd` — 사망 행동 베이스 인터페이스
  - `src/entities/enemies/base/enemy_defense.gd` — 데미지 감산 + 경직 저항 확률
- **구현 파일** (2-2b 나무/바위):
  - `data/enemies/tree_enemy.tres` 수정 — hitbox_size(50x28), offset(30,-14), duration 0.35s
  - `data/enemies/rock_enemy.tres` 수정 — damage_reduction_flat 3, hurt_resistance_chance 0.3
- **구현 파일** (2-2c 돌기둥 투사체):
  - `src/entities/enemies/base/behaviors/attack_behavior_ranged.gd` — 투사체 스폰 + 선딜(telegraph) + 근접 히트박스 차단
  - `src/entities/enemies/projectile/enemy_projectile.gd` — 투사체 엔티티 (직선 이동, 수명, 벽 충돌 소멸)
  - `src/entities/enemies/projectile/EnemyProjectile.tscn` — 투사체 씬 (Area2D + fallback ColorRect)
  - `data/enemies/pillar_enemy.tres` 수정 — attack_behavior="ranged", speed 200, lifetime 2.5, telegraph 0.4
- **구현 파일** (2-2d 꽃 분열):
  - `src/entities/enemies/base/behaviors/death_behavior_split.gd` — 사망 시 spore_count만큼 분열체 스폰
  - `data/enemies/flower_spore_enemy.tres` — 분열체 스탯 (작고 약함, is_spore=true, leaves_residue=false)
  - `data/enemies/flower_enemy.tres` 수정 — death_behavior="split", spore_count 2, radius 20
- **수정 파일**:
  - `src/entities/enemies/base/base_enemy.gd` — `_inject_behaviors`로 behavior 스크립트 주입, ATTACK 진입/종료 위임, take_damage 방어력 훅, _on_died 분열 훅
  - `src/entities/enemies/base/BaseEnemy.tscn` — AttackBehavior/DeathBehavior/Defense 3개 빈 Node 슬롯 추가
  - `data/enemies/enemy_stats_data.gd` — 행동 타입/히트박스 형상/방어/투사체/분열 총 14개 필드 추가
  - `src/systems/event_bus/event_bus.gd` — +2 시그널 (enemy_projectile_fired, enemy_split_spawned)
  - `src/entities/player/player_health.gd` — _on_enemy_attack_hit에 투사체 분기 추가 (area.is_in_group("enemy_projectile"))
- **설계 결정**:
  - 옵션 C(자식 Node 컴포넌트) + 옵션 B(데이터 필드) 하이브리드 패턴
  - 씬 4개(TreeEnemy 등) 대신 단일 BaseEnemy + stats_data.attack_behavior로 런타임 스크립트 주입 (서브 타입 확장성)
  - 부활 꽃과 분열체는 재분열 금지(`_is_revived or is_spore` → death_behavior 강제 none)
  - 투사체는 레이어 16(LAYER_ENEMY_ATTACK) 재사용, 플레이어 hurtbox 자동 감지
- **임시 밸런싱 값** (Phase 5에서 재조정):
  - 나무 히트박스 50x28 (기본 대비 1.67배)
  - 바위 방어 3 flat, 경직 저항 30%
  - 돌기둥 투사체 속도 200px/s, 수명 2.5s, 선딜 0.4s
  - 꽃 분열체 2마리, HP 30(원본 60의 50%), 분산 반경 20

#### 2-3. 땅거미 시스템
- [x] 잔류 부활 메카닉 (2-2 최소 범위) — 2-3a
- [x] 땅거미 엔티티 + 맵 이동 AI — 2-3b
- [x] HUD 경고 + 도착 이벤트 — 2-3c
- **의존성**: 2-4a (스테이지 시스템 기반)

#### 2-4. 스테이지 시스템
- [x] 3단계 클리어 (미클리어/절반/완전) — 2-4a
- [x] 스테이지 전환 (인접 포탈, 씬 로딩) — 2-4b
- [x] 잠금 프레임워크 + 빛 잠금 — 2-4c
- [x] 인접 맵 시간 전파 (50%) + 정화 프레임워크 — 2-4d
- [x] 독립 스테이지 시간 흐름 + 자동 재개/정지 — 2-4d+
- [x] 테스트 스테이지 3개 추가 — 2-4e
- **의존성**: Phase 1 완료
- **구현 파일** (2-4a):
  - `src/systems/stage/stage_system.gd` — Autoload 오케스트레이터
  - `src/systems/stage/stage_registry.gd` — 스테이지 데이터 저장/조회
  - `src/systems/stage/stage_clear_tracker.gd` — 클리어 상태 추적
  - `data/stages/stage_data.gd` — StageData Resource 클래스 (ClearState/LockType enum)
  - `data/stages/test_stage.tres` — 테스트 스테이지 데이터
- **구현 파일** (2-4b):
  - `src/entities/objects/portal/stage_portal.gd` — 포탈 엔티티 (Area2D, EventBus 통신)
  - `src/entities/objects/portal/StagePortal.tscn` — 포탈 씬 (재사용)
  - `src/systems/stage/stage_transition.gd` — 전환 연출 (페이드 + Player 보존/재삽입)
  - `src/world/stages/test_stage_2.gd` — 두 번째 테스트 스테이지
  - `src/world/stages/TestStage2.tscn` — 두 번째 테스트 스테이지 씬
  - `data/stages/test_stage_2.tres` — 두 번째 스테이지 데이터
- **구현 파일** (2-4c):
  - `src/systems/stage/stage_lock_validator.gd` — 잠금 유형별 검증 (LIGHT, PURIFY, ENVIRONMENT, ABILITY)
- **구현 파일** (2-4d):
  - `src/systems/stage/time_propagation.gd` — 독립 스테이지 시간 전파 (_process 기반, BFS 감쇠, 자동 재개/정지)
  - `data/stages/propagation_config_data.gd` — PropagationConfigData Resource 클래스
  - `data/stages/propagation_config.tres` — 전파 설정 (rate 0.5, threshold 0.05, max_depth 6)
  - `src/entities/enemies/shadow_residue/purification_detector.gd` — 정화 조건 감지 (등불 + 반대 시간대)
- **수정 파일** (2-4d/2-4d+):
  - `src/systems/event_bus/event_bus.gd` — 시간 전파 시그널 추가 (flow_rate_changed, time_flow_paused/resumed, time_hour_sync_requested, time_flow_resume_requested)
- **구현 파일** (2-4e):
  - `data/stages/test_stage_3.tres` — 새벽 6시, NONE, 적 3
  - `data/stages/test_stage_4.tres` — 황혼 18시, PURIFY(test_stage_2), 적 5
  - `data/stages/test_stage_5.tres` — 심야 3시, LIGHT, 적 1
  - `src/world/stages/test_stage_3.gd` + `TestStage3.tscn` — 수직 플랫폼 레이아웃
  - `src/world/stages/test_stage_4.gd` + `TestStage4.tscn` — 좁은 복도 + 단차 레이아웃
  - `src/world/stages/test_stage_5.gd` + `TestStage5.tscn` — 넓은 아레나 레이아웃
- **수정 파일** (2-4e):
  - `data/stages/test_stage.tres` — adjacent에 test_stage_3 추가
  - `data/stages/test_stage_2.tres` — adjacent에 test_stage_4 추가
  - `src/world/stages/TestStage.tscn` — 좌측 포탈(→test_stage_3) 추가
  - `src/world/stages/TestStage2.tscn` — 우측 포탈(→test_stage_4) 추가
  - `src/systems/time/time_system.gd` — 가변 속도 FLOWING, pause/resume, 자동 재개 핸들러
  - `src/systems/time/time_clock.gd` — advance_flow에 rate 파라미터, compute_full_flow_hours 추가
  - `src/systems/stage/stage_system.gd` — 독립 흐름 자동 재개/정지 분기, 전환 중 flow pause/resume

#### 2-5. 환경 오브젝트
- [x] **2-5a 거울/수정 (빛 분산 → 분열)** ✅
- [x] **2-5b 차폐물 (빛 차단 → 그림자 투영 영역 강도 override)** ✅
- [x] **2-5c 렌즈 (빛 집중 → 그림자 극도 축소, min 병합 override)** ✅
- [x] **2-5d 반사 바닥 (이중 약화, 정적/비상호작용)** ✅
- [x] 수동 조작 (시간 정지 중만, STOPPED 게이팅 — Phase 2-5a 베이스에서 확정)
- **의존성**: Phase 1 완료
- **2-5a 구현 파일**:
  - `data/environment/environment_object_data.gd` — 공통 베이스 Resource (object_name, prompt_text, can_interact, interaction_radius, influence_radius, sprite_path)
  - `data/environment/mirror_data.gd` — MirrorData (preset_count=4, beam_length=128, beam_angle_degrees=60, split_on_flow_start, default_shard_spore_path)
  - `data/environment/mirror_basic.tres` — 기본 거울 인스턴스
  - `data/enemies/shard_spore_enemy.tres` — 공용 폴백 스포어 ("그림자 파편", attack_behavior="none", is_spore=true, leaves_residue=false)
  - `src/entities/objects/environment/base/environment_object.gd` — Node2D 베이스, STOPPED 게이팅 + interact() 진입점
  - `src/entities/objects/environment/base/environment_influence_zone.gd` — Area2D, 영향권 적 추적
  - `src/entities/objects/environment/common/environment_prompt.gd` — Label fallback ("[E] <prompt_text>")
  - `src/entities/objects/environment/common/environment_highlight.gd` — Line2D fallback (40×56 노란 테두리)
  - `src/entities/objects/environment/mirror/mirror.gd` — 4프리셋 회전 + FLOWING 진입 시 분열
  - `src/entities/objects/environment/mirror/Mirror.tscn` — InteractionArea(layer 32) + RotationPivot(BeamVisual, InfluenceZone, MirrorBody) + Highlight + Prompt
  - `src/entities/enemies/base/behaviors/split_spawner.gd` — 분열 인프라 공용 헬퍼 (RefCounted 정적)
  - `src/entities/player/player_environment_interactor.gd` — Area2D(mask 32), 근접 오브젝트 자동 타겟팅 + E키 입력
- **2-5a 수정 파일**:
  - `src/entities/enemies/base/behaviors/death_behavior_split.gd` — split_spawner 사용으로 리팩토링
  - `src/entities/enemies/base/base_enemy.gd` — `trigger_split()` public API 추가, 재분열 가드(_is_revived/is_spore)
  - `src/entities/player/Player.tscn` — EnvironmentInteractor 노드 추가
  - `src/systems/event_bus/event_bus.gd` — +3 환경 시그널 (environment_interacted, environment_split_triggered, environment_blocked_shadow)
  - `project.godot` — +interact_environment InputMap (E키, 임시)
- **2-5a 아트 명세서**: `docs/art_specs/environment_mirror_art_spec.md`
- **2-5b 구현 파일**:
  - `data/environment/cover_data.gd` — CoverData (move_step_pixels, min/max_x_offset, block_mode 자리 확보(CREATE만), block_intensity, shadow_projection_length/width, projection_mode, body_size/color)
  - `data/environment/cover_basic.tres` — 기본 차폐물 인스턴스 (길이 96 / 폭 32 / 강도 0.9)
  - `src/entities/objects/environment/cover/cover.gd` — STOPPED 중 interact() = 플레이어 반대 방향 1스텝 밀기, 투영 영역 진입 적 강도 상시 override (max 병합), _process 매 프레임 재적용
  - `src/entities/objects/environment/cover/shadow_projection_zone.gd` — Area2D 브리지 (enemy_entered/exited 시그널)
  - `src/entities/objects/environment/cover/Cover.tscn` — Body(StaticBody2D layer 1 / Cover body 충돌) + InteractionArea(layer 32) + ShadowProjectionZone(mask 4) + Highlight + Prompt
- **2-5b 수정 파일**:
  - `src/world/stages/TestStage.tscn` — Cover1 인스턴스 배치 (360, 296)
- **2-5b 투영 방향**: 낮=태양 그림자 방향 그대로 / 밤=등불 반대 방향(get_night_shadow_params 위치 기반). 밤 등불 OFF 시 투영 없음.
- **2-5b 복원 로직**: 이탈 시 낮=EnemySystem.get_current_intensity, 밤+등불=ShadowSystem.get_intensity_at(enemy.global_position)
- **2-5c 구현 파일**:
  - `data/environment/lens_data.gd` — LensData (preset_count, beam_length, focus_zone_length/width, focus_intensity, body_size/color/border_color)
  - `data/environment/lens_basic.tres` — 기본 렌즈 인스턴스 (4프리셋 / 빔 160 / focus 48×24 / intensity 0.1)
  - `src/entities/objects/environment/lens/lens.gd` — 4프리셋 회전(거울 패턴) + FocusZone 진입 적 강도 min 병합 override (차폐물 대칭), _process 매 프레임 재적용
  - `src/entities/objects/environment/lens/Lens.tscn` — InteractionArea(layer 32) + RotationPivot(BeamVisual + FocusZone(mask 4) + LensBody + LensBorder) + Highlight + Prompt
- **2-5c 수정 파일**:
  - `src/entities/objects/environment/base/environment_influence_zone.gd` — enemy_entered/exited 시그널 추가 (lens 스트림 처리용, mirror는 영향 없음)
  - `src/world/stages/TestStage.tscn` — Lens1 인스턴스 배치 (200, 296)
- **2-5c 오버라이드 대칭**: 차폐물=max() 병합(강화), 렌즈=min() 병합(약화). focus_intensity=0.1(극도 약화)
- **2-5d 구현 파일**:
  - `data/environment/reflective_floor_data.gd` — ReflectiveFloorData (reflect_multiplier=0.5, body_size=(192,32), body_color 수면 청록)
  - `data/environment/reflective_floor_basic.tres` — 기본 반사 바닥 인스턴스 (can_interact=false)
  - `src/entities/objects/environment/reflective_floor/reflective_floor.gd` — 영역 내 적 강도 baseline × 0.5 상시 override, _process 매 프레임 재적용, EventBus 발신
  - `src/entities/objects/environment/reflective_floor/ReflectiveFloor.tscn` — InfluenceZone(Area2D mask 4, environment_influence_zone 공용) + FloorVisual. Highlight/Prompt/InteractionArea/StaticBody 생략
- **2-5d 수정 파일**:
  - `src/world/stages/TestStage.tscn` — ReflectiveFloor1 인스턴스 배치 (540, 312)
- **2-5d 오버라이드 축**: Cover=max(고정 강화), Lens=min(고정 약화), **반사 바닥=multiplier(baseline × 0.5 이중 약화)**. 다른 환경 오브젝트와 중첩 시 프레임 내 마지막 _process 실행이 승리(별도 병합 없음).

#### 2-6. 성장 시스템 ✅
- [x] 강화 포인트 획득 (처치/클리어)
- [x] 빛/그림자 투자 + 능력치 상승
- [x] 프로퍼티 (시간 자원) 투자
- [x] 리스펙
- **의존성**: 2-1
- **구현 파일**:
  - `data/growth/growth_config_data.gd` — GrowthConfigData Resource 클래스
  - `data/growth/growth_config.tres` — 수치 인스턴스
  - `src/systems/growth/growth_system.gd` — Autoload 오케스트레이터
  - `src/systems/growth/growth_point_tracker.gd` — 포인트 잔고/투자/리스펙
  - `src/systems/growth/growth_stat_calculator.gd` — 보너스 계산
- **수정 파일**:
  - `src/systems/event_bus/event_bus.gd` — +5 성장 시그널
  - `src/systems/combat/combat_system.gd` — 공격력 보너스 가산
  - `src/entities/player/player_health.gd` — HP 보너스 + growth_stats_changed
  - `src/systems/time/time_resource.gd` — 시간 최대치/회복량 보너스
  - `src/systems/shadow/shadow_system.gd` — 등불 범위 보너스
  - `src/entities/player/player_lantern.gd` — 등불 밝기 보너스
  - `src/systems/stage/stage_system.gd` — load_save_data를 save_manager에 위임
  - `src/systems/stage/save_manager.gd` — collect_data/apply_data에 growth 데이터 통합
  - `project.godot` — +GrowthSystem Autoload (EventBus 직후)

#### 2-7. 아이템/장비 시스템 ✅
- [x] 장착 슬롯 (무기 1 + 방어구 1 + 장신구 3)
- [x] 장비 능력치 적용 (성장 + 장비 합산, 방어력)
- [x] 소모품 (HP 회복 키1, 시간자원 회복 키2, 종류별 최대 3개)
- [x] 등급 체계 (일반/희귀/유니크, 강화 없음)
- [x] 인벤토리 UI (Tab), 소모품 HUD, 상점 UI
- [x] 드롭 시스템 (적 사망 확률 드롭 + 맵 배치)
- [x] 세이브/로드 통합
- **의존성**: 2-6
- **구현 파일**:
  - `data/items/item_data.gd` — ItemData Resource 베이스 (class_name)
  - `data/items/weapon_data.gd` — WeaponData (attack_bonus, speed, combo)
  - `data/items/armor_data.gd` — ArmorData (hp_bonus, defense_bonus)
  - `data/items/accessory_data.gd` — AccessoryData (5종 보너스 + special_effect_id)
  - `data/items/consumable_data.gd` — ConsumableData (type, amount, max_carry)
  - `data/items/weapons/sword_basic.tres` — 테스트 무기 (COMMON)
  - `data/items/weapons/sword_shadow.tres` — 테스트 무기 (RARE)
  - `data/items/armors/leather_vest.tres` — 테스트 방어구
  - `data/items/accessories/ring_of_strength.tres` — 테스트 장신구
  - `data/items/consumables/hp_potion.tres` — HP 회복 소모품
  - `data/items/consumables/time_crystal.tres` — 시간자원 회복 소모품
  - `src/systems/inventory/inventory_system.gd` — Autoload 오케스트레이터
  - `src/systems/inventory/item_registry.gd` — .tres 자동 로드/캐시
  - `src/systems/inventory/equipment_manager.gd` — 5슬롯 장착/해제
  - `src/systems/inventory/consumable_manager.gd` — 소모품 재고 관리
  - `src/systems/inventory/equipment_stat_calculator.gd` — 장비 보너스 합산
  - `src/ui/hud/ConsumableHud.tscn` + `consumable_hud.gd` — 소모품 HUD (2슬롯)
  - `src/ui/menus/inventory/inventory_menu.gd` — 인벤토리 메뉴 Autoload
  - `src/ui/menus/shop/shop_menu.gd` — 상점 메뉴 Autoload
  - `src/entities/objects/item_drop/item_drop.gd` + `ItemDrop.tscn` — 드롭 아이템 엔티티
  - `src/entities/npcs/shop_keeper/shop_keeper.gd` + `ShopKeeper.tscn` — 상점 NPC
- **수정 파일**:
  - `src/systems/event_bus/event_bus.gd` — +13 시그널 (아이템/장비/소모품/상점/드롭)
  - `src/entities/player/player_health.gd` — +장비 HP/방어 보너스, +소모품 HP 회복
  - `src/systems/combat/combat_system.gd` — +장비 공격력 보너스
  - `src/systems/time/time_resource.gd` — +장비 시간 보너스
  - `src/systems/time/time_system.gd` — +소모품 시간자원 회복
  - `src/entities/enemies/base/base_enemy.gd` — +enemy_drop_requested 발신
  - `src/entities/player/player.gd` — +inventory_opened/closed 입력 차단
  - `src/systems/stage/save_manager.gd` — +인벤토리 세이브/로드
  - `src/world/checkpoints/TestCheckpoint.tscn` — +ShopKeeper NPC
  - `project.godot` — +InventorySystem/InventoryMenu/ShopMenu Autoload, +consumable_1/2/inventory 입력

#### 2-8. 거점 시스템
- [x] 거점 씬 (회복, 세이브) — 2-8a
- [x] 월드맵 포탈 (거점 간 이동) + 월드맵 UI — 2-8b
- **의존성**: 2-4
- **구현 파일** (2-8b):
  - `src/ui/menus/world_map/world_map_ui.gd` — 월드맵 UI (독립 Autoload CanvasLayer, _process 폴링 입력)
  - `src/ui/menus/world_map/world_map_graph_builder.gd` — 노드/연결선 생성 + BFS 토폴로지 정렬 헬퍼
  - `src/entities/objects/portal/world_map_portal.gd` — 월드맵 포탈 (Area2D, interact 키)
  - `src/entities/objects/portal/WorldMapPortal.tscn` — 월드맵 포탈 씬
  - `src/world/checkpoints/test_checkpoint_2.gd` — 테스트 거점 2 스크립트
  - `src/world/checkpoints/TestCheckpoint2.tscn` — 테스트 거점 2 씬
  - `data/stages/test_checkpoint_2.tres` — 거점 2 StageData (is_checkpoint=true)
- **수정 파일** (2-8b):
  - `src/systems/event_bus/event_bus.gd` — +2 시그널 (world_map_opened/closed)
  - `src/systems/stage/stage_system.gd` — +거점 발견 추적(discovered_checkpoints) + 세이브/로드 + public API (get_discovered_checkpoints, get_stage_hour)
  - `src/entities/player/player.gd` — +_input_blocked (월드맵 열림 시 입력 차단, 중력/애니메이션 유지)
  - `data/stages/test_stage_4.tres` — +test_checkpoint_2 인접
  - `src/world/stages/TestStage4.tscn` — +PortalRight (→test_checkpoint_2)
  - `src/world/checkpoints/TestCheckpoint.tscn` — +WorldMapPortal 배치
  - `project.godot` — +WorldMapUI Autoload + interact 입력 액션
- **구현 파일** (2-8a):
  - `src/systems/stage/save_manager.gd` — JSON 세이브/로드 (StageSystem 자식 노드)
  - `src/world/checkpoints/test_checkpoint.gd` — 거점 씬 스크립트
  - `src/world/checkpoints/TestCheckpoint.tscn` — 거점 씬 (Floor, Walls, Portal, BG)
  - `data/stages/test_checkpoint.tres` — 거점 StageData (is_checkpoint=true)
- **수정 파일** (2-8a):
  - `src/systems/event_bus/event_bus.gd` — +3 시그널 (checkpoint_entered/exited, full_recovery_requested)
  - `data/stages/stage_data.gd` — +is_checkpoint 필드
  - `src/systems/time/time_resource.gd` — +full_recover()
  - `src/entities/player/player_health.gd` — +full_recovery_requested 핸들러
  - `src/entities/player/player.gd` — +checkpoint_entered 핸들러 (사망 상태 리셋)
  - `src/systems/time/time_system.gd` — +시간 잠금 + get_resource_data()
  - `src/systems/stage/stage_system.gd` — +거점 추적 + 세이브 통합
  - `src/systems/stage/stage_clear_tracker.gd` — +직렬화 + 잔류 복원
  - `src/systems/stage/stage_transition.gd` — +"checkpoint" 방향 (중앙 스폰)
  - `src/systems/combat/combat_system.gd` — +사망→거점 귀환 분기
  - `data/stages/test_stage_5.tres` — +test_checkpoint 인접
  - `src/world/stages/TestStage5.tscn` — +PortalLeft (→test_checkpoint)
  - `src/ui/hud/combat_hud.gd` — +사망 오버레이 거점 해제 + HP 회복 tween 연출
  - `src/ui/hud/time_hud.gd` — +시간자원 회복 tween 연출
  - `project.godot` — +debug_delete_save 입력 (Backspace)
- **알려진 제한** (2-8a): 세이브 로드 시 초기 씬이 1~2프레임 노출됨 — 타이틀/로딩 화면 추가 시 해결 예정

### Phase 2 완료 기준
```
거점에서 출발
  → 여러 스테이지 탐색 (잠금 경로 존재)
  → 시간 조작 + 전투 + 환경 활용
  → 적 처치 → 포인트 획득 → 성장 투자
  → 장비 획득/교체
  → 잔류 정화 → 완전 클리어
  → 땅거미 접근 → 대응
  → 거점 귀환 → 회복 → 재출발
```

---

## Phase 3 — 1구역 버티컬 슬라이스

> **목표**: 1구역(빛의 숲) 전체를 플레이 가능한 수준으로 완성
> **아트**: 1구역 아트 본격 제작 시작 (플레이어 + 1구역 적 + 1구역 타일 + 1구역 보스)

### 마일스톤

#### 3-1. 1구역 레벨 디자인 ✅ 완료 (2026-04-18)
- [x] 6개 일반 스테이지 레벨 설계 + 추가조작 1 (1-1 ~ 1-6 + 1-H)
- [x] 환경 오브젝트 배치 — 거울/차폐물/렌즈/반사 바닥 모든 Tier 1 유형 재사용
- [x] 잠금 유형 분포 — NONE 3(1-1, 1-2, 1-4) / LIGHT 1(1-3) / PURIFY 1(1-5) / ENVIRONMENT 1(1-6)
- [x] ENVIRONMENT 잠금 프레임워크 3종 선구현 — α `LightSensor` / β `EnvironmentStateRegistry` / γ `StateFlagPersistence` Autoload
- [x] `HiddenRevealer` 컴포넌트 — 4조건(LIGHT_SENSOR/REFLECTION/PURIFICATION/SHADOW_COVER), 2액션(QUEUE_FREE/SET_VISIBLE), StateFlags 영속화
- [x] 환경 오브젝트 확장 — Cover `PlayerShadowDetectZone`, Lens FocusZone layer=128 승격, ReflectiveFloor `LightEmitterZone`
- [x] EventBus 신규 시그널 — `light_sensor_toggled` / `environment_combo_changed` / `hidden_revealed` / `state_flag_changed`
- [x] SaveManager StateFlags 직렬화
- [ ] 자연 경계 시각화(강/개울 → 2구역 경계) — 아트 리소스와 함께 Phase 3-7에서 마감
- **의존성**: Phase 2 완료
- **상세**: `docs/PHASE_3_PLAN.md` §3, `docs/PHASE_3_1_COMPONENT_DESIGN.md`

#### 3-2. 1구역 적 ✅ 완료 (2026-04-18)
- [x] 나무/바위/꽃/돌기둥 서브 타입 (1구역 버전) — 어린 참나무 / 이끼 바위 / 빛 꽃 / 이정표 돌
- [x] 1구역 고유 적 1종 — 빛가루 포자 (공중 호밍, 빛 꽃 분열체로 스폰)
- [x] 공중 적 이동 프로파일 프레임워크 — `movement_profile` enum (ground / airborne_homing) + 중력 스킵 분기
- **의존성**: 3-1
- **상세**: `docs/PHASE_3_PLAN.md` §4, `docs/ENEMIES.md` §2
- **구현 파일** (3-2):
  - `data/enemies/zone1/oak_sapling.tres` — 어린 참나무 (HP 90, ATK 9, 히트박스 40×24, 범위 축소)
  - `data/enemies/zone1/moss_rock.tres` — 이끼 바위 (HP 130, hurt_resistance_chance 0.3→0.6, 경직 완화)
  - `data/enemies/zone1/light_flower.tres` — 빛 꽃 (HP 45, spore_count 2→3, spore_stats_path → pollen_spore)
  - `data/enemies/zone1/signpost_stone.tres` — 이정표 돌 (projectile_speed 200→140, telegraph 0.4→0.6)
  - `data/enemies/zone1/pollen_spore.tres` — 빛가루 포자 (HP 18, gravity_scale 0, movement_profile "airborne_homing", homing_turn_rate 3.5, homing_max_speed 55)
- **수정 파일** (3-2):
  - `data/enemies/enemy_stats_data.gd` — +3 필드 (movement_profile, homing_turn_rate, homing_max_speed)
  - `src/entities/enemies/base/enemy_movement.gd` — `_calculate_airborne()` 분기 (lerp 조향)
  - `src/entities/enemies/base/base_enemy.gd` — `gravity_scale==0` 시 중력/floor snap 스킵
  - `src/world/stages/Stage1_1.tscn` ~ `Stage1_6.tscn` + `Stage1_H.tscn` — `ext_resource` 경로를 `zone1/*.tres`로 교체 (7 씬)
  - `docs/ENEMIES.md` §2 — 서브 타입 + 고유 적 + 확장 필드 명세 추가
- **설계 결정**:
  - 빛가루 포자는 빛 꽃의 `spore_stats_path` 슬롯으로 연결 → 기존 `death_behavior_split` 인프라 100% 재사용, 별도 스폰 경로 없음
  - 공중 적은 데이터 전용 분기 (런타임 스크립트 스왑 회피, 컴포넌트 스크립트 일관성 유지)
  - 재분열 가드: `is_spore=true` + `death_behavior="none"` 이중
  - 테스트 스테이지(`TestStage*.tscn`)는 베이스 `.tres` 유지 (회귀 테스트용)

#### 3-3. 1구역 보스 ✅ 완료 (2026-04-18)
- [x] 보스 설계 (거대 고목 Ancient Oakheart, 2페이즈)
- [x] 보스 맵 설계 (stage_1_b 보스 아레나 + 숨겨진 2구역 포탈)
- [x] 보스 처치 보상 (빛 대시 능력 해금 + 성장 포인트 + 스토리 플래그 + 2구역 포탈 공개)
- **의존성**: 3-2
- **상세**: `docs/PHASE_3_PLAN.md` §5

#### 3-4. 거점 ✅ 완료 (2026-04-18)
- [x] 시작점 마을형 거점 (StartVillage, 상인 + 스토리 NPC 촌장)
- [x] 1-2 경계 간이형 거점 (BorderCheckpoint, stage_1_b ↔ stage_2_1 사이)
- [x] 거점 베이스 리팩터 — `checkpoint_base.gd` 공통 베이스 (기존 `test_checkpoint*.gd` 제거)
- [x] 대화 시스템 (노드 단위) — `DialogueBox` + `DialogueData` 리소스
- [x] NPC 공통 베이스 (`BaseNpc`) + ShopKeeper/StoryNpc 파생
- [x] 상인 첫 방문 대화 1회 분기 (StateFlags 영속화)
- **의존성**: 3-1
- **상세**: `docs/PHASE_3_PLAN.md` §6, `docs/CORE_SYSTEMS.md` §7

#### 3-5. 월드맵 (기본) ✅
- [x] 1구역 영역 표시 (zone_id + 라벨 + 구분선)
- [x] 시간 오버레이 (정지=채도0 / 낮=따뜻한 톤 / 밤=차가운 톤)
- [x] 거점 간 이동 (2-8b 완료)
- [x] 클리어 상태 표시 (테두리 색 — 2-8b + 3-5 폴리싱)
- [x] 땅거미 위치 아이콘 (⚠ placeholder, Phase 3-7에서 교체)
- **의존성**: 3-4
- **상세**: `docs/PHASE_3_PLAN.md` §7

#### 3-6. UI 완성
- [x] 인게임 HUD Pass 1 (33ac495 — HP pip/콤보/속성 오브/스킬 슬롯/포션/시간 코어 placeholder, 4분면 배치)
- [x] 인게임 HUD Pass 2 §2.2 (ba721ad — A-7 스킬 슬롯 원형 링 + 쿨다운 스윕 + 이끼 배경 + 아이콘 교보재)
- [x] 인게임 HUD Pass 2 §2.3 (2026-04-18 — HP pip 호흡/저체력 맥동 + 자원 링 호흡/저자원 맥동)
- [~] 인게임 HUD Pass 2 §2.1 (B-6 arc_mask shader — **영구 보류 확정** 2026-04-18, draw_arc placeholder 체감 검증 통과)
- [ ] 인게임 HUD 미니맵
- [x] 타이틀 화면 (2026-04-19 — 새 게임/이어하기/설정/종료 + 세이브 감지 + 덮어쓰기 확인 + fade in/out + game_start_requested 시그널 구동)
- [ ] 일시정지 메뉴
- [ ] 장비 관리 메뉴 폴리싱 (Tab 인벤토리는 2-7에서 기본 구현)
- [ ] 스킬 관리 메뉴 (4슬롯 장착/해제 + 상세)
- [ ] 맵 상세 패널
- **의존성**: Phase 2 완료
- **상세**: `docs/UI_IMPLEMENTATION_PLAN.md` (A/B 카테고리 Pass 구조) / `docs/PHASE_3_PLAN.md` §8

#### 3-7. 1구역 아트 적용
- [ ] 플레이어 스프라이트 + 애니메이션
- [ ] 1구역 타일셋 (빛의 숲)
- [ ] 1구역 적/보스 스프라이트
- [ ] 1구역 배경
- [ ] UI 아트
- [ ] 이펙트 (공격, 피격, 그림자 등)
- **의존성**: Art Spec Writer 명세서 기반, 3-1~3-6 구현 완료 후

#### 3-8. 사운드 (기본)
- [ ] 효과음 (공격, 피격, 시간 조작, 적 처치)
- [ ] 1구역 BGM
- **의존성**: 3-1

### Phase 3 완료 기준
```
타이틀 → 게임 시작
  → 시작 마을에서 출발
  → 1구역 6스테이지 + 추가조작 발견
  → 모든 스테이지 완전 클리어
  → 1구역 보스 전투 + 처치
  → 보상 획득 (능력 + 스토리 단서 + 강화)
  → "1구역 클리어" — 2구역 해금
  → 첫 플레이 체험 완결
```

**이 시점에서 외부 피드백 수집 가능 (데모 빌드)**

---

## Phase 4 — 전체 콘텐츠

> **목표**: 2~5구역 전체 + 스토리 완성
> **아트**: 구역별 순차 제작

### 4-A. 2구역 — 안개 습지
- [ ] 8개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (2페이즈)
- [ ] 거점 (2-3 경계 마을형 + 간이형)
- [ ] 아트 + 사운드

### 4-B. 3구역 — 폐허의 숲
- [ ] 10개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (3페이즈, 전환점)
- [ ] 거점 (3-4 경계 마을형)
- [ ] 스토리 전환점 연출
- [ ] 아트 + 사운드

### 4-C. 4구역 — 그림자 숲
- [ ] 12개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (3페이즈)
- [ ] 거점 (4구역 내부 간이형 + 4-5 경계 간이형)
- [ ] 아트 + 사운드

### 4-D. 5구역 — 봉인의 심부
- [ ] 14개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 최종 보스 (4페이즈, 두 왕가의 결합체)
- [ ] 거점 (5구역 내부 간이형)
- [ ] 엔딩 연출
- [ ] 아트 + 사운드

### 4-E. 전체 연결
- [ ] 월드맵 전체 완성 (5구역 + 거점 8개)
- [ ] 스킬 전체 구현 (18개)
- [ ] 강화 이동 해금 (빛 대시, 그림자 점프 등)
- [ ] 장비/장신구 전체 목록
- [ ] 추가조작 4개 완성
- [ ] 스토리 전체 흐름 (컷신, 기록물)

### Phase 4 완료 기준
```
1구역부터 5구역까지 전체 플레이 가능
  → 50스테이지 + 보스 5개 완전 클리어 가능
  → 스토리 처음부터 엔딩까지 완결
  → 모든 스킬, 장비, 장신구 획득 가능
```

---

## Phase 5 — 폴리싱

> **목표**: 출시 품질 달성

### 5-1. 밸런싱
- [ ] 그림자 배율 곡선 (선형 vs 곡선) 확정
- [ ] 시간 자원 초기치/회복량
- [ ] 땅거미 이동 속도
- [ ] 적/보스 능력치 전체 조정
- [ ] 강화 포인트 분배 비율
- [ ] 소모품 최대 소지량
- [ ] 장비/장신구 수치

### 5-2. 아트 폴리싱
- [ ] 스프라이트 최종 리비전
- [ ] 배경 레이어 (패럴랙스)
- [ ] 파티클 이펙트 추가
- [ ] UI 최종 디자인

### 5-3. 사운드 완성
- [ ] 전 구역 BGM
- [ ] 보스전 BGM
- [ ] 환경음
- [ ] 효과음 보강

### 5-4. QA
- [ ] 전체 플레이스루 테스트 (3회 이상)
- [ ] 엣지 케이스 테스트 (자원 0, 경계 시간, 동시 이벤트)
- [ ] 성능 프로파일링
- [ ] 메모리 누수 점검

### 5-5. 접근성 / 편의
- [ ] 키 리바인드
- [ ] 컨트롤러 지원
- [ ] 해상도/창 모드 설정
- [ ] 세이브 슬롯 관리
- [ ] 튜토리얼/힌트 시스템

---

## Phase 6 — 출시

### 6-1. Steam 준비
- [ ] Steam 개발자 계정
- [ ] 스토어 페이지 (스크린샷, 트레일러, 설명)
- [ ] Steam 실적/업적 연동
- [ ] 클라우드 세이브

### 6-2. 빌드
- [ ] Windows EXE 빌드 + 테스트
- [ ] macOS 빌드 + 테스트
- [ ] Linux 빌드 + 테스트

### 6-3. 출시
- [ ] 얼리 액세스 or 정식 출시 결정
- [ ] 출시일 설정
- [ ] 출시

---

## 의존성 맵

```
Phase 1 (코어 프로토타입)
  │
  ├─ 1-1 플레이어 이동
  │       │
  │       ▼
  │   1-2 테스트 스테이지
  │       │
  │       ▼
  │   1-3 시간 시스템
  │       │
  │       ▼
  │   1-4 그림자 시스템 ──────┐
  │       │                   │
  │       ▼                   ▼
  │   1-5 적 (기본)       1-7 등불
  │       │
  │       ▼
  │   1-6 전투 (기본)
  │
  ▼
Phase 2 (시스템 확장)
  │
  ├─ 2-1 전투 확장 ─────── 2-6 성장 ─── 2-7 아이템
  ├─ 2-2 적 확장 ────────── 2-3 땅거미
  ├─ 2-4 스테이지 ────────── 2-8 거점
  └─ 2-5 환경 오브젝트
  │
  ▼
Phase 3 (1구역 버티컬 슬라이스)
  │
  ├─ 3-1 레벨 디자인 ──┬── 3-2 적 ── 3-3 보스
  │                     ├── 3-4 거점
  │                     └── 3-5 월드맵
  ├─ 3-6 UI
  ├─ 3-7 아트 (구현 완료 후)
  └─ 3-8 사운드
  │
  ▼
Phase 4 (전체 콘텐츠: 2~5구역 순차)
  │
  ▼
Phase 5 (폴리싱)
  │
  ▼
Phase 6 (출시)
```

---

## 아트 제작 타임라인

> 코드와 아트는 병행 진행. Art Spec Writer가 구현 완료 시 명세서를 생성하면, 사용자가 Aseprite에서 제작.

| 시점 | 아트 작업 |
|---|---|
| Phase 1 | 없음 (플레이스홀더) |
| Phase 2 | 플레이어 기본 스프라이트 시작 가능 |
| Phase 3 | 플레이어 완성 + 1구역 적/보스/타일/배경/UI/이펙트 |
| Phase 4-A | 2구역 아트 |
| Phase 4-B | 3구역 아트 |
| Phase 4-C | 4구역 아트 |
| Phase 4-D | 5구역 아트 |
| Phase 5 | 전체 리비전 + 파티클/이펙트 추가 |

---

## 구현 현황 요약 (최종 업데이트: 2026-04-18, Phase 3-6 UI Pass 2 §2.3 완료)

| Phase | 마일스톤 | 상태 | 비고 |
|---|---|---|---|
| 0 | 기반 세팅 | ✅ 완료 | 문서 12개, 에이전트 7개, project.godot, EventBus |
| 1-1 | 플레이어 기본 이동 | ✅ 완료 | Composition 패턴 5개 컴포넌트, 예시 스프라이트로 동작 확인 |
| 1-2 | 테스트 스테이지 | ✅ 완료 | ColorRect 플레이스홀더, TileMap은 Phase 3 이관 |
| 1-3 | 시간 시스템 | ✅ 완료 | Composition 6개 컴포넌트, HUD, TimeConfigData |
| 1-4 | 그림자 시스템 | ✅ 완료 | ShadowSystem Autoload + Calculator + Caster, Curve 슬롯 |
| 1-5 | 적 시스템 (기본) | ✅ 완료 | 4종 적 + AI + 그림자 잔류 |
| 1-6 | 기본 전투 | ✅ 완료 | CombatSystem Autoload + 4타 콤보 + HP/사망/리스폰 + 전투 HUD |
| 1-7 | 등불 (기본) | ✅ 완료 | PlayerLantern 컴포넌트 + PointLight2D + 밤 per-object 그림자 + per-enemy 강도 |
| **2-4a** | **스테이지 시스템 기반** | **✅ 완료** | **StageSystem Autoload + StageData + 3단계 클리어 상태** |
| **2-4b** | **스테이지 전환** | **✅ 완료** | **StagePortal(윗방향키) + 페이드 전환 + Player 보존 + 적 유지 + 스테이지별 독립 시간** |
| **2-8a** | **거점 씬 (회복, 세이브)** | **✅ 완료** | **거점 진입→완전 회복(tween 연출) + 시간 잠금 + 사망→거점 귀환 + JSON 세이브/로드 + Backspace 세이브 삭제** |
| **2-8b** | **월드맵 포탈 + 월드맵 UI** | **✅ 완료** | **월드맵 UI + 거점 간 이동 + 테스트 거점 2** |
| **2-3a** | **잔류 부활 메카닉** | **✅ 완료** | **잔류 부활(HP 50%, 공격력 150%) + 그림자 잠금 + 적 HP 바** |
| **2-3b** | **땅거미 엔티티 + AI** | **✅ 완료** | **땅거미 맵 이동 AI + 전투 엔티티** |
| **2-3c** | **땅거미 HUD 경고** | **✅ 완료** | **접근 경고 HUD + 도착 이벤트** |
| **2-1** | **전투 확장** | **✅ 완료** | **SkillSystem 프레임워크 + 4슬롯 + 쿨다운 + 피니시 속성 + 자동 회복 + 스킬 HUD** |
| **2-6** | **성장 시스템** | **✅ 완료** | **GrowthSystem Autoload + 포인트 획득/투자/리스펙 + 5개 시스템 보너스 연동 + 세이브/로드** |
| **2-7** | **아이템/장비 시스템** | **✅ 완료** | **InventorySystem Autoload + 5슬롯 장비 + 소모품(2종) + 드롭 + 상점 + 인벤토리/소모품 HUD + 세이브/로드** |
| **2-2** | **적 확장 (행동 차별화)** | **✅ 완료** | **AttackBehavior/DeathBehavior/Defense 컴포넌트 + 4종 차별화 (나무 범위/바위 방어/돌기둥 투사체/꽃 분열) + EnemyProjectile** |
| **2-5a** | **환경 오브젝트 — 거울** | **✅ 완료** | **EnvironmentObjectData 베이스 + MirrorData(4프리셋, 60°/128px 부채꼴) + STOPPED 게이팅 + FLOWING 진입 시 분열 + split_spawner 공용화 + BaseEnemy.trigger_split() + shard_spore_enemy.tres 폴백 + EventBus 3시그널 + interact_environment(E키)** |
| **2-5b** | **환경 오브젝트 — 차폐물** | **✅ 완료** | **CoverData(move_step=16, 투영 96×32, 강도 0.9) + STOPPED 중 밀기(±64) + ShadowProjectionZone(mask 4) + 영역 내 적 강도 상시 override(max 병합, _process 재적용) + 낮=태양방향/밤=등불반대 투영 방향 회전 + 이탈 시 per-object 강도 복원** |
| **2-5c** | **환경 오브젝트 — 렌즈** | **✅ 완료** | **LensData(4프리셋, 빔 160/focus 48×24, intensity 0.1) + STOPPED 중 회전(거울 패턴) + FocusZone(mask 4, RotationPivot 자식) + 영역 내 적 강도 상시 override(min 병합, Cover 대칭, _process 재적용) + environment_influence_zone 시그널 확장 재사용** |
| **2-5d** | **환경 오브젝트 — 반사 바닥** | **✅ 완료** | **ReflectiveFloorData(reflect_multiplier=0.5, body 192×32 수면 청록) + 정적/비상호작용(can_interact=false) + InfluenceZone(mask 4, environment_influence_zone 공용) + 영역 내 적 baseline × 0.5 상시 override(multiplier 방식, Cover/Lens와 다른 축) + _process 재적용 + TestStage 배치** |
| **3-1** | **1구역 레벨 디자인** | **✅ 완료** | **7 스테이지(1-1~1-6 + 1-H) .tres/.tscn/.gd + ENVIRONMENT 잠금 3종 프레임워크(α LightSensor / β EnvironmentStateRegistry / γ StateFlagPersistence Autoload) + HiddenRevealer 컴포넌트(4조건/2액션/StateFlags 영속화) + Cover `PlayerShadowDetectZone` + Lens FocusZone layer=128 승격 + ReflectiveFloor `LightEmitterZone` + EventBus 4시그널 신설 + StageLockValidator prefix 파싱(`light_sensor:`/`registry:`/`flag:`) + SaveManager StateFlags 직렬화** |
| **3-2** | **1구역 적 (서브 타입 + 고유 적)** | **✅ 완료** | **서브 타입 4종(`data/enemies/zone1/` — oak_sapling / moss_rock / light_flower / signpost_stone) + 고유 적 빛가루 포자(pollen_spore, 공중 호밍) + EnemyStatsData 확장(movement_profile / homing_turn_rate / homing_max_speed) + enemy_movement.gd `_calculate_airborne()` 분기(lerp 조향) + base_enemy.gd 중력 스킵(gravity_scale=0) + Stage1_*.tscn 7개 ext_resource 경로 치환 + 빛 꽃 spore_stats_path로 포자 연결(기존 split 인프라 100% 재사용) + 재분열 이중 가드(is_spore + death_behavior=none)** |
| **3-3** | **1구역 보스 (거대 고목)** | **✅ 완료** | **거대 고목 보스 + AbilitySystem + 빛 대시 + ABILITY 잠금 (5f534ce)** |
| **3-4** | **거점 (시작 마을 + 1-2 경계)** | **✅ 완료** | **BaseNpc/DialogueBox/checkpoint_base 리팩터 + 시작 마을 + 1-2 경계 (d85c2e0)** |
| **3-5** | **월드맵 (시간 오버레이 + 땅거미 + 영역)** | **✅ 완료** | **zone_id 영역 그룹핑(D10) + 시간 오버레이 채도0(D11) + 땅거미 ⚠ 아이콘(D12) + zone_layout 분리 (167cde7)** |
| **3-6 Pass 1** | **UI 기반 프레임워크 (placeholder)** | **✅ 완료** | **4분면 배치 + HP pip 5개 + 콤보 오브/도트 + 스킬 슬롯 완만한 오름 호 + 포션 병 + 시간 코어(궤도/일식/배지) (33ac495). `propagation_origin_changed` 시그널 신설** |
| **3-6 Pass 2 §2.2** | **스킬 슬롯 원형 렌더 + 쿨다운 스윕** | **✅ 완료** | **skill_slot.gd 분리 + 링 2px/쿨다운 시계 스윕/이끼 배경/ready 펄스/flash/icon_path PNG fallback (ba721ad)** |
| **3-6 Pass 2 §2.3** | **호흡/저체력 펄스** | **✅ 완료** | **HP pip 호흡(STOPPED 1.0s ±5%) + 저체력(<20%) 0.8s 붉은 맥동 + 자원 링 호흡(FLOWING 1.0s) + 저자원(<20%) 0.8s 금↔붉은 보간 맥동. `EventBus.time_state_changed` 구독, 조건부 queue_redraw로 상시 갱신 방지** |

### Phase 2 세부 작업 순서

```
2-4a 스테이지 시스템 기반 ✅
  │
  ├── 2-4b 스테이지 전환 (인접 포탈, 씬 로딩) ✅
  │     │
  │     ├── 2-4c 잠금 프레임워크 + 빛 잠금 ✅
  │     ├── 2-4d 시간 전파 + 정화 프레임워크 ✅
  │     └── 2-4e 테스트 스테이지 3개 추가 ✅
  │           │
  │           ├── 2-8a 거점 씬 (회복, 세이브) ✅
  │           │     │
  │           │     └── 2-8b 월드맵 포탈 + 월드맵 UI
  │           │
  │           └── 2-3a 잔류 부활 메카닉 (2-2 최소)
  │                 │
  │                 └── 2-3b 땅거미 엔티티 + 맵 이동 AI
  │                       │
  │                       └── 2-3c 땅거미 HUD 경고 ✅
  │
  │
  2-1 전투 확장 ✅
  │   SkillSystem 프레임워크 + 4슬롯 + 쿨다운
  │   피니시 속성 (장착 스킬 다수결)
  │   자동 회복 (STOPPED 상태)
  │   스킬 HUD + 테스트 스킬 2개
  │
  └── 2-6 성장 시스템 ✅
      GrowthSystem + PointTracker + StatCalculator
      강화/프로퍼티 포인트 체계
      5개 시스템 보너스 연동 + 혼합 해금 + 리스펙
      세이브/로드 통합
        │
        └── 2-7 아이템/장비 시스템 ✅
            InventorySystem + 4 컴포넌트
            5슬롯 장비 + 소모품 2종 + 드롭 + 상점
            인벤토리 메뉴 + 소모품 HUD + 상점 메뉴
            세이브/로드 통합
  │
  합의된 결정:
  - 정화: 프레임워크만 (해금은 Phase 3)
  - 잠금: 프레임워크 + 빛 잠금만 (나머지 Phase 3)
  - 적 확장: 땅거미에 필요한 최소 범위(잔류 부활)만
  - Phase 2-1: "프레임워크 우선, 콘텐츠 나중에" 전략
    - 스킬 로직 구조만 만들고, 실제 18개 스킬은 데이터(.tres)로 나중에 조립
    - 속성 배율은 전부 1.0으로 설정 (Phase 5 밸런싱에서 조정)
  - 이후 작업 순서: 2-6 성장 → 2-7 아이템/장비 → 2-2 적 확장 → 2-5 환경 오브젝트
  - 2-5 세부 순서: 2-5a 거울(완료) → 2-5b 차폐물(완료) → 2-5c 렌즈(완료) → 2-5d 반사 바닥
```

### 프로젝트 설정 변경 이력
- **스트레치 모드**: `viewport` → `canvas_items` (Phase 1-3에서 변경. UI 텍스트 선명도 확보, 스프라이트는 snap_2d로 픽셀 유지)
- **밤 색조**: `(0.15, 0.1, 0.25)` → `(0.4, 0.35, 0.55)` (캐릭터 식별 가능한 수준으로 조정)
- **기준 사이즈 변경** (Phase 1-4): 타일 32x32→64x64, 해상도 384x216→640x360, 스케일 5배→3배, 중력 980→1960. 플레이어 스탯 화면비 보정 적용. 기존 스프라이트시트(64x64)는 미교체 — 128x128 아트 제작 시 Player.tscn 갱신 필요.
- **카메라 제한**: TestStage에 Camera2D limit 설정 추가 (스테이지 범위 내로 제한)

---

## 미결 사항 (개발 계획 관련)

- [ ] 각 Phase의 예상 소요 기간은 산정하지 않음 (프로토타입 진행 속도 보고 판단)
- [ ] 얼리 액세스 여부 (Phase 3 완료 후 판단 가능)
- [ ] 외부 피드백 수집 시점 (Phase 3 데모 빌드 유력)
- [ ] 사운드/음악 제작 방식 (직접 제작? 외주? 에셋 구매?)
- [x] Phase 1-1 구현에 대한 Code Reviewer / QA 에이전트 실행 → max_air_jumps 하드코딩 수정 완료
- [x] Phase 1-3 구현에 대한 Code Reviewer / QA 에이전트 실행 → resource_changed 시그널 연결 등 3건 수정 완료
- [x] Phase 2 진입 시 base_enemy.gd set_deferred 버그 수정 (monitoring/monitorable 시그널 중 직접 변경 → set_deferred)
- [x] Phase 2 완료 후 전반 점검 (CLI 3종 + 에이전트 3인 + 시나리오 검증) — 2026-04-18
  - `43dd449` fix: 밤 등불 토글 시 적 강도 즉시 반영 (enemy_system._on_lantern_toggled — per-object/전역 강도 모드 즉시 전환)
  - `822327c` fix: 땅거미 시간 전파 rate 반영 (DuskSpiderSystem — flow_rate_changed/pause/resume 수신, effective_delta 적용)
- [x] Phase 3 진입 전 설계 문서 갱신 6건 — 2026-04-18 (SKILLS.md, BOSSES.md, WORLD_DESIGN.md, ENEMIES.md, COMBAT.md, DEVELOPMENT_PLAN.md)
- [x] Phase 3 진입 노트 작성 — 2026-04-18 (`docs/PHASE_3_PLAN.md`)
- [x] Phase 3-2 1구역 적 구현 완료 — 2026-04-18 (서브 타입 4종 + 빛가루 포자 + EnemyStatsData airborne 필드 확장)
- [x] Phase 3-2 파급 문서 갱신 — 2026-04-18 (GDD.md §4.4/§6.2/§17, CORE_SYSTEMS.md 섹션 번호, ENEMIES.md §2)
