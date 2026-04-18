# 시간이 멈춘 숲 — 핵심 로직 시스템

> 이 문서는 게임의 모든 시스템이 의존하는 기반 메카닉을 정의한다.
> 스킬, 맵, 성장 등 상위 시스템은 여기서 확정된 규칙 위에서 설계된다.

---

## 1. 낮/밤 사이클

### 기본 규칙
- 낮/밤 경계: **06:00 (일출), 18:00 (일몰)**
- 플레이어가 직접 낮↔밤 전환 불가 — 시간 흐름으로만 전환
- 플레이어 조작 가능 범위: 경계 10분 전까지 (05:50, 17:50)
  - 경계 근처까지 밀어붙이면 간접적 낮밤 전환 가능
- **디폴트 상태: 시간 정지**

### 두 가지 시간 행동

| 구분 | 트리거 | 속도 | 자원 | 적 상태 |
|---|---|---|---|---|
| **시간 조작** | 버튼 꾹 누름 | 빠름 (연출) | 소모 | 없음 |
| **시간 흐름** | 조작 후 해제/방치 | 1분 = 1시간 | 회복 | 활성화 |

- **시간 조작**: 멈춘 상태에서만 가능. 원하는 시각까지 빠르게 이동. 자원 소모. 태양이 빠르게 움직이는 연출.
- **시간 흐름**: 조작 없이 시간이 자연히 진행. 적 활성화. 자원 회복. 16:00에 흘리면 실시간 4분 뒤 20:00.

### 데드락 없음
- 자원이 없어도 시간 흐름은 항상 가능
- 자원 부족 = 원하는 시각을 못 맞춘 채 전투해야 하는 페널티

### 구현 상태 (Phase 1-3 + 2-4d+ 완료)
- **구현 완료**: 시간 상태 머신(STOPPED/MANIPULATING/FLOWING), 시간 조작/흐름, 자원 소모/회복, 낮밤 경계, CanvasModulate, HUD
- **가변 속도 흐름 (Phase 2-4d+)**: TimeSystem이 `flow_rate_changed` 시그널로 흐름 속도를 동적으로 조정. 시간 전파 시 인접 스테이지 rate(50% 등)로 감속 흐름 지원. 시간 자원 소모/회복은 항상 100% 속도 (rate 무관).
- **일시정지/재개**: `time_flow_paused`/`time_flow_resumed` 시그널로 스테이지 전환 중 흐름 일시정지 지원
- **자동 재개**: `time_flow_resume_requested(hour, rate)` 시그널로 독립 흐름 중인 스테이지 진입 시 해당 rate로 FLOWING 자동 전환
- **수치 외부화**: `data/time/time_config.tres`에서 모든 수치 조정 가능
- **초기 수치**: 조작 속도 3.0시간/초, 자원 최대 100, 소모 10/시간, 회복 5/시간

### 미결 사항
- [ ] 시간 조작 속도 최종 확정 (현재 3.0시간/초, 플레이테스트로 조정)
- [ ] 시간 자원 초기 최대치/회복속도 최종 확정 (현재 100/5.0)
- [x] 시간 흐름 중 시간 조작 재개 가능 — 언제든 버튼을 눌러 정지+재조작 가능. 자원/밸런싱으로 남용 방지.

---

## 2. 그림자 크기 ↔ 적 강도

### 기본 규칙
- 모든 적은 오브젝트(나무, 바위, 꽃, 돌기둥 등)의 그림자에서 생성
- 그림자 크기가 적 강도를 결정 — **연속적 연동** (scale이 변할수록 강도도 연속으로 변함)
- 강도는 HP, 공격력, 속도를 동시에 조정하는 **통합 배율**로 적용

### 낮과 밤의 반전 관계

| 시간대 | 그림자 짧음 | 그림자 김 |
|---|---|---|
| **낮** | 20% (최약) | 150% (최강) |
| **밤** | 150% (최강) | 20% (최약) |

- **낮**: 정오(그림자 최소) → 20%. 경계 근처(05:50/17:50, 그림자 최대) → 150%
- **밤**: 등불 가까이(그림자 짧음) → 150%. 등불 멀리(그림자 김) → 20%
- 경계 근처에서 밤 전환을 기다리는 플레이 = 150% 강도의 적을 감수해야 하는 리스크

### 구현 방향 (확정)
- 엔진 물리 그림자(Light2D/Shadow2D) 미사용
- 그림자를 **스프라이트**로 처리
  - 방향: 시간 변수(태양 각도)에 따라 offset 조절
  - 길이: 시간 변수에 따라 scale 조절
  - 적 강도 = shadow scale을 20%~150% 범위로 매핑한 통합 배율
- 밤: 등불 위치 기반으로 동일한 공식 반전 적용

### 구현 상태 (Phase 1-7 + 2-3a 완료)
- **구현 완료**: ShadowSystem Autoload, ShadowCalculator(순수 계산), ShadowCaster(오브젝트 컴포넌트)
- **낮 그림자**: 태양 각도(0°~180°) → 방향(cos), 스케일(1-sin) → 강도(20%~150%) 연속 매핑
- **밤 그림자**: 등불 기반 per-object 계산. 등불 OFF 시 그림자 없음(강도 0).
- **그림자 잠금**: FLOWING 진입 시 그림자 크기/강도 고정, STOPPED 시 해제+재계산 (Phase 2-3a)
- **수치 외부화**: `data/shadow/shadow_config.tres`에서 모든 수치 조정 가능
- **Curve 슬롯**: intensity_curve가 null이면 선형, Curve 리소스 설정 시 곡선 매핑
- **fallback**: 그림자 스프라이트 아트 없이도 ColorRect로 동작
- **시스템 간 통신**: EventBus.sun_state_updated 수신, EventBus.shadow_params_changed 발신 (직접 참조 없음)

### ShadowCaster 컴포넌트 확장 (Phase 1-5)
- `anchor_at_base` 모드 추가: 발밑 고정 + 방향으로 뻗는 그림자 (적 등 지상 엔티티용)
- `shadow_z_index` export 추가: 오브젝트별 그림자 렌더링 순서 제어 가능
- 기존 환경 오브젝트용 오프셋 이동 모드는 `anchor_at_base = false`(기본값)로 유지

### 그림자 잠금 (Phase 2-3a 확정)
- **핵심 규칙**: 시간이 흐르기 시작하면(FLOWING 진입) 그림자 크기가 **그 시점의 값으로 고정**된다.
  - 낮: 태양 각도 갱신을 무시 → 그림자 크기/강도 고정
  - 밤: 등불 위치 변화를 무시 → per-object 그림자 크기/강도 고정
- **해제**: 시간이 다시 멈추면(STOPPED) 잠금 해제. 현재 상태로 즉시 재계산.
- **적 HP 초기화**: FLOWING 진입 시 모든 적의 HP가 최대치로 리셋됨.
  - 이유: "데미지 → 시간 정지 → 리포지션 → 다시 흐름" 치즈 전략 방지
- **구현**:
  - `ShadowSystem._locked` — 전역 파라미터 갱신 차단
  - `ShadowCaster._locked` — 개별 그림자 비주얼 갱신 차단 (낮 시그널 + 밤 _process 모두)
  - `EnemySystem._activate_enemies()` — 활성화 시 현재 강도 적용 + HP 리셋
  - 잠금 해제 시 양쪽 모두 현재 상태(is_day, lantern_active 등)로 재동기화

### 등불 시스템 연동 (Phase 1-7 + 2-6 완료)
- **등불 컴포넌트**: `src/entities/player/player_lantern.gd` — Node2D, PointLight2D 자식
- **조작**: L키로 ON/OFF 토글 (시간 정지 중에도 가능)
- **밤 per-object 계산**: 밤+등불 ON 시 ShadowCaster가 `_process`에서 `ShadowSystem.get_night_shadow_params(자기위치)` 호출
- **범위**: `lantern_config.tres`의 `max_range` (기본 200px) 밖 오브젝트는 그림자 미생성
- **반전 로직**: 등불 가까이 → 그림자 짧음 → 강도 150%(최강), 등불 멀리 → 그림자 김 → 강도 20%(최약)
- **등불 OFF 시**: 밤에 그림자 없음 (적도 없음 상태)
- **per-enemy 강도**: ShadowCaster가 `shadow_scale_changed(instance_id, intensity)` 시그널 발신 → EnemySystem이 해당 적만 갱신
- **수치 외부화**: `data/lantern/lantern_config.tres`
- **성장 보너스 연동 (Phase 2-6)**: 빛 투자 시 등불 범위(+15px/pt, ShadowSystem) 및 밝기(+0.05 energy/pt, PlayerLantern) 증가. `growth_stats_changed` 시그널로 동적 반영.

### 미결 사항
- [ ] scale과 강도의 매핑 곡선 (현재 선형, Curve 슬롯 준비됨 — 프로토타입으로 결정)

---

## 3. 시간 자원

### 기본 규칙
- 시간 조작(스크러빙) 시 소모 — 인게임 시간당 고정량 소모
- 시간 정지 상태: 소모 없음, 회복 없음
- **빡빡한 자원**: 매 스테이지를 최적 조건(20%)으로 싸우는 것은 불가능. 스테이지별 자원 분배 필요.
- 자원이 없어도 시간 흐름은 가능 — 데드락 없음. 자원 부족 = 불리한 조건으로 싸우는 페널티.

### 소비 수단

| 수단 | 조건 | 성격 |
|---|---|---|
| **시간 조작** | 버튼 꾹 누름 (MANIPULATING) | 인게임 시간당 고정량 소모 |
| **스킬 사용** | 스킬 발동 시 (Phase 2-1) | 스킬별 `time_cost` 만큼 즉시 소비 (flat) |

### 회복 수단 (4가지)

| 수단 | 조건 | 성격 |
|---|---|---|
| **시간 흐름 자동 회복** | 시간이 흐르는 중 (적 활성화 상태) | 기본 베이스. 리스크 감수 필요. |
| **아이템/소모품** | 탐색 보상으로 획득 | 비상용 탈출구. |
| **처치 시 회복** | 적 처치 시 일부 회복 | 공격적 플레이 장려. |
| **거점 완전 회복** | 거점 진입 시 | 시간 자원 + HP 동시 전량 회복 (Phase 2-8a) |

### 거점 시스템 연동
- **거점 맵**: 완전 회복
- 거점에서 멀어질수록 자원 고갈 → 싸움 조건이 점점 거칠어짐 → 탐색 깊이의 전략적 판단

### 구현 상태 (Phase 1-3 + 2-1 + 2-6 + 2-7 + 2-8a 완료)
- **자동 회복**: 시간 흐름 중 인게임 시간당 5.0 회복 (구현 완료)
- **처치 시 회복**: EventBus.enemy_killed 수신 시 고정 3.0 회복 (구현 완료)
- **아이템 회복**: `consumable_used` 시그널 수신 → TIME_RECOVER 타입일 때 recover_flat(amount) 호출 (Phase 2-7 연결 완료)
- **스킬 소비**: consume_flat() — 스킬별 time_cost 만큼 즉시 소비 (Phase 2-1)
- **거점 완전 회복**: full_recover() — 거점 진입 시 전량 회복 (Phase 2-8a)
- **성장 보너스 연동 (Phase 2-6)**: 프로퍼티 투자 시 시간 자원 최대치(+10/pt) 및 회복량(+1.0/pt) 증가. `growth_stats_changed` 시그널로 동적 반영.
- **장비 보너스 연동 (Phase 2-7)**: 장비/장신구의 time_max_bonus, time_recovery_bonus 합산. `equipment_stats_changed` 시그널로 동적 반영.

### 미결 사항
- [ ] 초기 최대치 / 초기 회복속도 최종 확정 (현재 100 / 5.0, 프로토타입으로 조정)
- [ ] 아이템 획득 빈도 및 회복량 (밸런싱)
- [ ] 스킬별 time_cost 밸런싱 (현재 테스트 스킬: 빛 베기 5.0, 그림자 강타 10.0)

---

## 4. 땅거미 시스템

### 기본 규칙
- 시간이 흐르는 맵을 감지하고 찾아오는 특수 적
- **복수 존재 가능** — 월드맵 전체에 최대 3마리 동시 존재
- **우선 타겟**: 플레이어가 있는 시간이 흐르는 스테이지. 플레이어가 정지 스테이지에 있으면 시간이 흐르는 스테이지를 향해 이동.
- **스폰 조건**: 시간이 흐르기 시작하면(FLOWING) 플레이어로부터 3~5맵 거리에 스폰

### 이동 속도 (확정)
- **맵 1개 이동 = 실시간 2분 (120초, 인게임 2시간)**
- 고정 타이머 없음 — 현재 위치와 목표 맵 사이의 거리가 곧 남은 시간
- BFS 경로탐색으로 스테이지 인접 그래프를 따라 이동

| 거리 | 도착까지 | 체감 |
|---|---|---|
| 1맵 (인접) | 2분 | 매우 급박 |
| 3맵 | 6분 | 한 전투 세션 |
| 6맵 | 12분 | 낮 1사이클과 동일, 여유 |

### 도착 시 행동 (동시 발생)
1. **즉시 강화** — 해당 맵의 모든 그림자 적 HP/공격력 ×1.3 (+30%)
2. **잔류 부활** — 그림자 잔류(처치된 적의 흔적) 재소환
3. **전투 가능 적으로 등장** — 처치 시 위협 제거 가능 (HP 200, 공격력 45, 처치 포인트 50)

### 대응 방법
- 도착 전 시간을 정지시켜 감지를 끊음
- 땅거미째 처치

### 확정 수치 (DuskSpiderConfigData)

| 항목 | 키 | 값 |
|---|---|---|
| 맵당 이동 시간 | seconds_per_map | 120초 |
| 최소 스폰 거리 | spawn_distance_min | 3맵 |
| 최대 스폰 거리 | spawn_distance_max | 5맵 |
| 최대 동시 존재 | max_spiders | 3 |
| 강화 HP 배율 | reinforce_hp_multiplier | 1.3 |
| 강화 ATK 배율 | reinforce_atk_multiplier | 1.3 |
| 전투 HP | combat_hp | 200 |
| 전투 공격력 | combat_attack | 45 |
| 처치 포인트 | defeat_points | 50 |

### 구현 상태 (Phase 2-3c 완료)
- **DuskSpiderSystem**: Autoload. 시간 흐름 감지 → 스폰 → 이동 추적 → 도착 처리 → 전투 엔티티 스폰 → HUD 로딩
- **DuskSpiderNavigator**: BFS 경로탐색. StageSystem의 인접 그래프 기반 최단 경로 계산
- **DuskSpiderEntity**: RefCounted 데이터 객체. 상태 머신 (IDLE → TRACKING → ARRIVED → DEFEATED)
- **DuskSpiderConfigData**: Resource 클래스. 모든 수치 외부화 (`data/dusk_spider/dusk_spider_config.tres`)
- **DuskSpiderCombat**: BaseEnemy 확장 전투 엔티티 (`dusk_spider_combat.gd` + `DuskSpiderCombat.tscn`)
  - 플레이어가 있는 스테이지에 땅거미 도착 시 플레이어 근처(±120px)에 스폰
  - 잔류를 남기지 않음 (`leaves_residue = false`). 처치 시 논리 엔티티 자동 정리
  - 스탯: `data/enemies/dusk_spider_stats.tres` (HP 200, ATK 45)
- **도착 시 처리**: EnemyStats.reinforce() + EventBus.residue_revival_requested + 전투 엔티티 스폰
- **시스템 간 통신**: EventBus.dusk_spider_spawned / dusk_spider_approached / dusk_spider_arrived / dusk_spider_defeated / enemy_reinforce_requested
- **접근 시그널 통합**: 프레임당 1회, 가장 가까운 거리만 발신 (변화 시에만 emit)
- **DuskSpiderHud**: CanvasLayer HUD (우상단). 2맵 이내 접근 시 보라색 맥동 경고, 1맵 시 긴급, 도착 시 플래시+스케일 연출
  - fallback 비주얼: ColorRect 12x12 보라색. `fx_spider_warning.png` 존재 시 TextureRect 자동 교체
  - 시간 정지 → 경고 숨김, 모든 땅거미 처치 → 자동 해제

### 미결 사항
- [ ] 땅거미 자체 공격 패턴
- [x] ~~이동 속도 수치 확정~~ → 120초/맵 확정
- [x] ~~강화 수치~~ → HP/ATK ×1.3 (+30%) 확정
- [x] ~~전투 엔티티 씬 및 스폰 로직~~ → Phase 2-3b에서 구현 완료
- [ ] 땅거미 자체 처치 난이도 및 드롭 (밸런싱 시 결정)
- [ ] 땅거미 전용 아트 리소스 (현재 fallback 사각형 사용)

---

## 5. 환경 오브젝트 (Environment Objects)

### 기본 규칙
- 시간 정지 상태(STOPPED)에서만 수동 조작 가능 (Phase 2-5a 확정)
- 시간 흐름 진입(FLOWING) 시 효과 발동, 흐르는 동안 상태 고정
- "세팅(STOPPED) → 실행(FLOWING)" 리듬을 강제

### 공통 아키텍처 (Phase 2-5a)
- **EnvironmentObjectData (Resource)**: 오브젝트 공통 메타. `object_name`, `prompt_text`, `can_interact`, `interaction_radius`, `influence_radius`, `sprite_path`
- **environment_object.gd (Node2D 베이스)**: STOPPED 상태 게이팅(`is_operable`), `interact()` 진입점, `EventBus.time_state_changed` 수신
- **environment_influence_zone.gd (Area2D)**: 영향권 내 적 추적. `get_tracked_enemies()` 제공
- **environment_prompt.gd / environment_highlight.gd**: fallback 비주얼 (Label / Line2D)
- **콜리전 레이어 32 (environment)**: 오브젝트의 InteractionArea가 사용. 플레이어의 `EnvironmentInteractor`(mask 32)가 감지
- **입력**: `interact_environment` (E키, 임시. 전체 키맵 재조정 시 변경 예정)
- **플레이어**: `player_environment_interactor.gd` (Area2D). 근접 오브젝트 자동 타겟팅 + 입력 처리

### 거울 (Mirror) — Phase 2-5a 완료
- **데이터**: `MirrorData` (extends EnvironmentObjectData) — `preset_count(4)`, `initial_preset_index`, `beam_length(128)`, `beam_angle_degrees(60)`, `split_on_flow_start(true)`, `default_shard_spore_path`
- **회전**: STOPPED 중 E키 입력으로 4프리셋(90°씩) 순환. `RotationPivot` 노드 회전.
- **분열 발동**: FLOWING 진입 시 `_apply_split_to_zone()` 호출 → 영향권 내 적에게 `BaseEnemy.trigger_split(fallback)` 일괄 적용
- **분열 인프라 공용화**:
  - `split_spawner.gd` (RefCounted 정적 헬퍼) — 적 사망 분열(`death_behavior_split`)과 거울 분열이 공용
  - `BaseEnemy.trigger_split(fallback_spore_path, count, spread_radius)` public API — 사망 없이 외부 트리거. 드롭/잔류 미발생 (전투 처치가 아니므로)
  - 재분열 가드: `_is_revived` 또는 `stats_data.is_spore=true`인 적은 무시
- **공용 폴백 스포어**: `data/enemies/shard_spore_enemy.tres` ("그림자 파편", HP 25, attack 3, `attack_behavior="none"`, `is_spore=true`, `leaves_residue=false`). 적별 `spore_stats_path`가 있으면 그것을 우선 사용 (Plan C).
- **EventBus 시그널**:
  - `environment_interacted(object_id, state_index)` — 회전 등 상호작용
  - `environment_split_triggered(object_id, enemy_ids)` — 거울 분열 발동
  - `environment_blocked_shadow(cover_id, caster_id, blocked)` — 차폐물 투영 영역 출입 알림 (Phase 2-5b 가동)

### 차폐물 (Cover) — Phase 2-5b 완료
- **데이터**: `CoverData` (extends EnvironmentObjectData) — `move_step_pixels(16)`, `min_x_offset(-64)`, `max_x_offset(64)`, `block_mode(CREATE)`, `block_intensity(0.9)`, `shadow_projection_length(96)`, `shadow_projection_width(32)`, `projection_mode(LIGHT_OPPOSITE)`, `body_size(24×64)`, `body_color`
  - `BlockMode` enum: `CREATE / REMOVE / BOTH` — Phase 2-5b는 CREATE만 구현, 나머지는 자리 확보
  - `ProjectionMode` enum: `LIGHT_OPPOSITE`(빛 반대 방향) / `LOCAL_FIXED`(차폐물 local 고정)
- **이동(밀기)**: STOPPED 중 E키 입력으로 플레이어 반대 방향 1스텝(±16px, ±64px 클램프) 이동. `EventBus.environment_interacted(object_id, step_index)` 발신.
- **그림자 투영 영역 (ShadowProjectionZone)**:
  - `Area2D` (collision layer 0, mask 4 = enemy). 본체 기준 부채꼴 대신 직사각형(96×32) 투영.
  - `ProjectionMode.LIGHT_OPPOSITE`: 낮=`ShadowSystem.get_shadow_direction()` / 밤=`ShadowSystem.get_night_shadow_params(global_position).direction`. 밤+등불 OFF 시 투영 각도 0 (사실상 비활성).
  - `EventBus.shadow_params_changed` 수신 시 투영 방향 재계산 (회전만 갱신, 위치 고정).
- **강도 override (CREATE 모드)**:
  - 영역 진입: `enemy.update_intensity(maxf(현재, block_intensity))` — max() 병합으로 더 강한 쪽이 적용
  - 매 프레임 재적용(`_process` → `_reapply_override_to_all`): EnemySystem 브로드캐스트가 override를 덮어쓰는 것을 무효화
  - 영역 이탈: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)` 로 복원. 밤+등불 OFF는 override 대상 자체가 없음.
  - `EventBus.environment_blocked_shadow(cover_id, enemy_id, blocked)` 발신.
- **콜리전 구조**: Body(StaticBody2D layer 1 / 플레이어·적 물리 차단) + InteractionArea(layer 32) + ShadowProjectionZone(mask 4) + Highlight + Prompt

### 렌즈 (Lens) — Phase 2-5c 완료
- **데이터**: `LensData` (extends EnvironmentObjectData) — `preset_count(4)`, `initial_preset_index`, `beam_length(160)`, `focus_zone_length(48)`, `focus_zone_width(24)`, `focus_intensity(0.1)`, `body_size(24×24)`, `body_color`, `body_border_color`
- **회전**: STOPPED 중 E키 입력으로 4프리셋(90°씩) 순환. `RotationPivot` 노드 회전 (거울과 동일 패턴).
- **집광 영역 (FocusZone)**:
  - `Area2D` (collision layer 0, mask 4 = enemy). 빔 끝단 좁은 구간(48×24)에만 배치 — "다수 중 하나만 골라 약화" 감각.
  - `RotationPivot` 자식으로 배치되어 프리셋 회전 시 함께 회전.
  - `environment_influence_zone.gd` 재사용 (mirror와 공용). 스트림 처리용 `enemy_entered/exited` 시그널 추가.
- **강도 override (min 병합, 차폐물의 대칭)**:
  - 영역 진입: `enemy.update_intensity(minf(현재, focus_intensity))` — min() 병합으로 더 약한 쪽이 적용
  - 매 프레임 재적용(`_process` → `_reapply_override_to_all`): EnemySystem 브로드캐스트 무효화
  - 영역 이탈: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)` 로 복원.
  - `EventBus.environment_blocked_shadow(lens_id, enemy_id, blocked)` 발신 (시그널 시그니처 재사용).
- **콜리전 구조**: InteractionArea(layer 32) + RotationPivot { BeamVisual + FocusZone(mask 4) + LensBody + LensBorder } + Highlight + Prompt
- **본체 물리**: 없음 — 렌즈는 빛을 집중하는 광학 장치이므로 플레이어/적을 물리적으로 차단하지 않음 (차폐물과의 차이점)

### 반사 바닥 (Phase 2-5d 완료)
- **컨셉**: 정적/비상호작용 지형. 영역 내 적 그림자 강도를 baseline의 절반으로 상시 축소 (이중 약화).
- **Resource 데이터 (`ReflectiveFloorData`)**:
  - `reflect_multiplier: float = 0.5` — baseline에 곱하는 계수 (0.5 = 이중 약화)
  - `body_size: Vector2 = (192, 32)` — 가로 긴 수면 영역 fallback
  - `body_color: Color = (0.165, 0.29, 0.353, 0.65)` — 수면 청록 반투명
  - 베이스 `can_interact = false`, `interaction_radius = 0.0` (플레이어 상호작용 타겟 제외)
- **영역 감지**: `environment_influence_zone` 재사용 (Area2D layer 0 / mask 4). `enemy_entered/exited` 시그널로 스트림 추적.
- **강도 override (multiplier 방식, Cover/Lens와 다른 축)**:
  - 영역 진입: `enemy.update_intensity(clampf(baseline × 0.5, 0, 1))` — 곱셈으로 "이미 약한 그림자도 절반으로, 강한 그림자도 절반으로"
  - baseline: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)`
  - 매 프레임 재적용(`_process` → `_reapply_override_to_all`): EnemySystem 브로드캐스트 무효화
  - 영역 이탈: baseline 값으로 복원
  - `EventBus.environment_blocked_shadow(floor_id, enemy_id, blocked)` 발신 (시그널 시그니처 재사용)
- **다른 환경 오브젝트와 중첩**: 별도 병합 없음 — 프레임 내 마지막 `_process` 실행이 승리. Phase 5 밸런싱 시 재검토.
- **콜리전 구조**: InfluenceZone(Area2D mask 4) { CollisionShape2D + FloorVisual }. Highlight/Prompt/InteractionArea/StaticBody 생략 (비상호작용 + 플레이어는 기존 Floor 위로 걸음).

### 센서/드러내기 레이어 (Phase 3-1 + 3-3-d 확장 완료)
- **LightSensor (`src/entities/objects/environment/light_sensor/`)**: Area2D (layer 64 SENSOR / mask 128 LIGHT_BEAM). 렌즈 FocusZone 또는 반사 바닥의 방출 영역이 mask 128로 승격되면 겹침으로 점등. `EventBus.light_sensor_toggled(sensor_id, is_on)` 발신. ENVIRONMENT α validator 역할을 겸함 (별도 validator 없이 `StageLockValidator`가 직접 구독).
- **HiddenRevealer (`src/entities/objects/environment/hidden_revealer/`)**: **5가지 조건(LIGHT_SENSOR / REFLECTION / PURIFICATION / SHADOW_COVER / FLAG)** 중 하나 충족 시 `target_node_path` 대상을 드러냄. `SET_VISIBLE` 액션은 `visible=true` 외에 `process_mode=INHERIT`도 복원하여 숨김 포탈의 Area2D 신호를 재활성화. 드러낸 후 `StateFlags`에 `hidden_revealer.<stage_id>.<node_name>` 플래그를 기록 → 재진입 시 즉시 `force_reveal()`.
  - **FLAG 조건 (Phase 3-3-d 추가)**: `trigger_flag_id`에 지정된 StateFlag가 true가 되면 reveal. `EventBus.state_flag_changed` 구독. 보스 처치 보상(스토리 플래그)이 다음 구역 진입 포탈을 노출하는 경로로 사용됨.
- **Cover.ShadowProjectionZone의 플레이어 감지 확장**: `PlayerShadowDetectZone`(자식 Area2D, layer 0 / mask 2)을 추가. 부모(투영 영역) 회전을 상속받아 "플레이어가 차폐물 그림자 안에 있음"을 감지 — SHADOW_COVER 조건의 소스.

### 미결 사항
- [ ] 차폐물 `BlockMode.REMOVE / BOTH` (현재 CREATE만 구현)
- [ ] 거울/차폐물/렌즈/반사 바닥 전용 아트 리소스 (현재 ColorRect/Polygon2D fallback)
- [ ] 키맵 재조정 시 `interact_environment` 액션 최종 키 결정

---

## 6. 영구 능력 시스템 (Ability)

### 기본 규칙
- 보스 처치 시 영구적으로 해금되는 이동/탐색 능력. 스킬 포인트와 **완전히 분리**된 별도 축 (SKILLS.md §5.3 참조).
- 각 능력은 특정 스테이지의 **ABILITY 잠금**을 통과시키는 키 역할을 겸함. 메트로배니아 진행 구조의 핵심.
- 세이브/로드는 `AbilitySystem.get_save_data` / `load_save_data`로 영구 보존.

### 구현 상태 (Phase 3-3-d 완료)

- **`AbilitySystem` Autoload** (`src/systems/ability/ability_system.gd`) — 능력 보유(`_owned: Dictionary`) 및 보스 보상 분배를 단일 책임으로 처리
  - `has(ability_id) -> bool` — 보유 여부 조회 (`stage_lock_validator`, `player_state_machine`이 사용)
  - `unlock(ability_id, source)` — 신규 해금 시 `EventBus.ability_unlocked` 발신 + `AbilityData.unlock_story_flag` 설정
  - `get_data(ability_id) -> AbilityData` — 표시명/아이콘 조회
  - `get_all_owned()`, `get_save_data()`, `load_save_data()`
- **`AbilityData` Resource** (`data/abilities/ability_data.gd`) — id / display_name / description / category / icon_path / unlock_story_flag
  - `_ready`에서 `data/abilities/*.tres`를 자동 스캔하여 등록
- **1구역 첫 능력**: `data/abilities/light_dash.tres` (id="light_dash", category="dash")
- **보스 보상 분배** (§BOSSES.md §3 참조):
  - `EventBus.boss_defeated` 수신 → `BossStatsData`의 5가지 보상 필드 자동 분배
  - 스캔은 `data/bosses/**/*.tres` 재귀 (신규 구역 추가 시 별도 등록 불필요)
- **ABILITY 잠금 게이트** (`StageLockValidator._validate_ability`):
  - `StageData.lock_requirement`에 ability_id 직접 기재 (예: `lock_requirement = "light_dash"`)
  - `AbilitySystem.has(req)`로 통과 여부 판정, 실패 시 `AbilityData.display_name`을 사유 메시지에 포함
- **플레이어 조작 통합** (빛 대시 기준):
  - `PlayerStateMachine.State.LIGHT_DASH` — 일반 `DASH`와 병렬 상태. `_check_dash_inputs`에서 light_dash가 보유 시 일반 dash보다 우선
  - `PlayerLightDash` 컴포넌트 — 상태 진입 시 `player_health.set_invulnerable(iframe)` 호출
  - `PlayerStatsData`: `light_dash_speed`, `light_dash_duration`, `light_dash_cooldown`, `light_dash_iframe`
  - `player_health.set_invulnerable(duration)` — 기존 `_invincible_timer`를 공유. 진행 중 무적보다 긴 시간만 덮어씀. `_start_invincibility`는 매번 `_config.invincible_duration`으로 `wait_time`을 복원하여 일반 피격 i-frame이 영구 변경되지 않도록 보장.
  - InputMap `light_dash` = **O키** (skill_3가 K를 점유하므로 우측 클러스터 내 미사용 키 선정)

### 미결 사항
- [ ] 2~5구역 능력 후보 목록 확정 (빛/그림자 테마 배분)
- [ ] 능력별 UI 아이콘 (Phase 3-7)
- [ ] 해금 연출 / 튜토리얼 (Phase 3-6~3-7)

---

## 7. 거점·NPC·대화 시스템 (Phase 3-4)

### 거점 (Checkpoint)
- `CheckpointBase` 스크립트(`src/world/checkpoints/checkpoint_base.gd`)가 모든 거점 씬의 공통 베이스.
  - `@export`: `stage_id` / `spawn_point` / `bg_path` / `ground_tile_path`
  - `_ready`에서 `stage_entered`/`spawn_point_set` emit + 카메라 640×360 limit + BG/Ground fallback 적용
  - `StageData.is_checkpoint=true` 시 StageSystem이 자동으로 완전 회복·세이브·월드맵 discovery 처리 (별도 등록 API 없음)
- **거점 목록 (1구역)**:
  - `StartVillage` (`start_village`) — 시작 마을. ShopKeeper + StoryNpc(촌장) 배치. stage_1_1 좌측과 연결
  - `BorderCheckpoint` (`border_checkpoint`) — 1↔2구역 경계. NPC 없음, 오브젝트만. stage_1_b ↔ stage_2_1 사이

### NPC (BaseNpc)
- `src/entities/npcs/base/base_npc.gd` — Area2D 공통 베이스
  - 플레이어 body_entered/exited 감지 + HintLabel on/off
  - `Input.is_action_just_pressed("interact")` → 가상 메서드 `npc_interacted()` 호출
  - `set_interaction_blocked(bool)` — 대화/UI 진행 중 재입력 방지
- **파생 클래스**:
  - `ShopKeeper` — 첫 방문 시 `first_greeting: DialogueData` 재생 → `shop_opened` emit. 이후 바로 UI. 플래그 `shop_keeper.{shop_id}.greeted`를 `StateFlags`에 영속화
  - `StoryNpc` — `dialogue: DialogueData`를 매번 재생 (스킵 없음)

### 대화 시스템 (Dialogue)
- **Autoload 아님**. 재사용 UI `DialogueBox`(CanvasLayer, `src/ui/common/dialogue/dialogue_box.gd`)를 NPC가 런타임 인스턴스화해 `current_scene.add_child` 후 `queue_free`
- **데이터**: `DialogueData` 리소스 (`data/dialogues/dialogue_data.gd`) — `dialogue_id` / `speaker` / `lines: Array[String]`. 구역별 서브폴더 (`data/dialogues/zone1/`)
- **진행 키**: `interact`(F) 재사용. start 시 `call_deferred("_arm")`으로 첫 프레임 input 겹침 방지
- **입력 잠금**: DialogueBox가 `player.set_physics_process(false)` 토글 (종료 시 복원). 플레이어 스크립트는 대화 인지 책임 없음
- **EventBus 시그널**:
  - `dialogue_started(npc_id: String)`
  - `dialogue_finished(npc_id: String)` — NPC가 구독해 후속 동작 트리거 (예: 상인이 첫 인사 후 상점 오픈)
- **미지원 (후속 리팩터)**: 분기 / 변수 / 다국어 / 타이핑 효과(Phase 3-7로 묶음)

---

## 시스템 간 상호작용

```
[시간 조작] ── 자원 소모 ──▶ [시간 자원] ◀── 자원 소비 ── [스킬 사용]
     │                           │
     ▼                           ▼ (회복: 흐름 중 / 처치 / 아이템 / 거점)
[낮/밤 사이클 진행]
     │
     ├─ 태양 각도 변화
     │       │
     │       ▼
     │  [그림자 크기] ──▶ [적 강도] (20% ~ 150%)
     │  (낮: 짧을수록 약 / 밤: 짧을수록 강)
     │
     └─ 시간 흐름 감지
             │
             ▼
        [땅거미 이동]
        (2분/맵, 복수 존재)
             │
             ▼ 도착 시
        적 강화 + 잔류 부활 + 전투 적 등장
```
