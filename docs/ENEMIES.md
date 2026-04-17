# 시간이 멈춘 숲 — 3. 적 시스템

> 이 문서는 그림자 적의 종류, 행동 패턴, 생성 규칙을 정의한다.
> 핵심 로직 시스템(CORE_SYSTEMS.md)과 전투 시스템(COMBAT.md) 위에서 설계된다.

---

## 1. 그림자 적 기본 규칙

### 생성 원리
- 숲의 오브젝트(나무, 바위, 꽃, 돌기둥 등)의 그림자에서 생성
- 시간이 흐르면 등장
- 그림자 크기가 적 강도를 결정 (20%~150%, 통합 배율)
- 원본 오브젝트의 형태가 적의 행동 패턴을 결정

### GDD 확정 적 유형

| 오브젝트 | 그림자 적 특성 |
|---|---|---|
| 나무 | 크고 느림, 범위 넓음 |
| 바위 | 작고 단단함, 잘 안 줄어듦 |
| 꽃 | 빠르고 약함, 여러 마리 분열 |
| 돌기둥 | 길고 가늘게 뻗음, 원거리 공격 |

---

## 2. 적 유형 구조

### 베이스 4종 + 구역별 서브 타입 (확정)
- 기본 4종(나무, 바위, 꽃, 돌기둥)은 **행동 규칙의 베이스**
- 각 구역마다 같은 오브젝트의 **서브 타입** 등장
  - 외형, 공격 패턴이 다른 거의 별개의 적
  - 베이스의 핵심 특성은 유지 (나무 = 크고 범위 넓음 등)
  - 예: 1구역 참나무(느린 근접) vs 3구역 고목(원거리 포자)
- **구역 고유 적**: 해당 구역에만 존재하는 새로운 오브젝트에서 생성되는 완전 신규 적
  - 베이스 4종과 무관한 새로운 행동 규칙
  - 구역의 테마와 연결 (예: 유적 구역 → 석상에서 생성되는 적)

### 유형별 그림자 크기 반응 (확정)

| 유형 | 반응 | 범위 | 특성 |
|---|---|---|---|
| 나무 | 표준 | 20%~150% | 기본 |
| 바위 | 둔감 | 40%~150% | 최대한 약화해도 40%까지만 |
| 꽃 | 민감 | 10%~150% | 약화 잘 되지만 강할 때 더 강함 |
| 돌기둥 | 표준 | 20%~150% | 기본 |

- 서브 타입과 구역 고유 적도 각각 고유한 반응 특성을 가질 수 있음

### 구현 상태 (Phase 1-5 + 2-2 + 2-3a 완료)
- **구현 완료**: EnemySystem Autoload, EnemyRegistry(적 추적), EnemyIntensity(강도 계산)
- **베이스 적 엔티티**: 컴포넌트 기반 구성 (StateMachine, Stats, Movement, AnimationController, HPBar, AttackBehavior, DeathBehavior, Defense)
- **AI 상태 머신**: DORMANT → IDLE → PATROL → CHASE → ATTACK → HURT → DEAD
- **그림자 강도 연동**: ShadowSystem 강도 → 유형별 재매핑 → HP/공격력/속도 실시간 조정
- **시간 흐름 연동**: FLOWING → 적 활성화, STOPPED/MANIPULATING → 적 비활성화
- **그림자 잠금 연동**: FLOWING 진입 시 그림자 강도 고정 + HP 최대치 리셋 (치즈 전략 방지)
- **그림자 잔류**: 처치 시 위치에 마커 생성, 부활 메카닉은 땅거미 시스템에서 처리
- **HP 바**: 적 머리 위 HP 바 컴포넌트 (`enemy_hp_bar.gd`). 데미지 시 표시, 풀 HP 시 숨김. 30% 이하 색상 변경.
- **DORMANT 비주얼**: fallback 초기 색상이 DORMANT_COLOR(어둡고 반투명)로 설정. 활성화 시 밝은 색으로 전환.
- **수치 외부화**: `data/enemies/` 하위 .tres 파일에서 모든 수치 조정 가능
- **fallback 비주얼**: 아트 없이 ColorRect로 동작
- **시스템 간 통신**: EventBus.time_state_changed/shadow_params_changed 수신, enemy_spawned/enemy_killed/residue_left/enemy_projectile_fired/enemy_split_spawned 발신

### 유형별 행동 차별화 (Phase 2-2 완료)
컴포넌트 패턴: `AttackBehavior` / `DeathBehavior` / `Defense` 3개 자식 슬롯에 stats_data.attack_behavior/death_behavior 값을 보고 런타임에 스크립트 주입.

| 유형 | AttackBehavior | DeathBehavior | Defense | 핵심 특성 |
|---|---|---|---|---|
| 나무 | melee (히트박스 50x28, 0.35s) | none | 기본 | 넓은 범위, 오래 지속 |
| 바위 | melee (기본 30x20) | none | 감산 3, 경직 저항 30% | 단단함, 경직 잘 안 됨 |
| 꽃 | melee (기본 30x20) | split (2마리, 반경 20) | 기본 | 처치 시 분열체 스폰 |
| 돌기둥 | ranged (투사체 200px/s, 2.5s, 선딜 0.4s) | none | 기본 | 근접 히트박스 차단, 원거리 공격 |

- **투사체 엔티티**: `EnemyProjectile.tscn` (레이어 16 재사용, 벽 충돌 시 소멸, 수명 만료 시 소멸)
- **분열체**: `flower_spore_enemy.tres` (HP 30, 공격력 4, 크기 14x14, is_spore=true, leaves_residue=false)
- **재분열 방지**: 부활(`_is_revived`) 또는 분열체(`is_spore`)는 death_behavior를 강제로 none 설정
- **잔류 폭발 방지**: 분열체는 `leaves_residue=false`로 잔류 미생성

### 미결 사항
- [ ] 구역별 서브 타입 목록
- [ ] 각 서브 타입별 공격 패턴
- [ ] 구역 고유 오브젝트 및 신규 적 종류
- [ ] 서브 타입/구역 고유 적의 그림자 반응 수치
- [ ] Phase 5 밸런싱: 나무 히트박스 크기, 바위 방어 수치, 돌기둥 투사체 속도/선딜, 꽃 분열체 개수/HP

---

## 3. 땅거미 (특수 적)

CORE_SYSTEMS.md에서 확정:
- 시간이 흐르는 맵을 감지하고 찾아옴
- 복수 존재 가능 (최대 3마리 동시)
- 2분/맵 속도로 이동
- 스폰 거리: 플레이어로부터 3~5맵 떨어진 위치
- 도착 시: 적 강화(+30%) + 잔류 부활 + 전투 적 등장

### 확정 수치 (Phase 2-3b)

| 항목 | 값 | 비고 |
|---|---|---|
| 이동 속도 | 120초/맵 | 실시간 2분 |
| 스폰 거리 | 3~5맵 | 플레이어 기준 |
| 최대 동시 존재 | 3마리 | DuskSpiderConfigData |
| 강화 배율 (HP) | ×1.3 | 도착 맵 적 전체 |
| 강화 배율 (공격력) | ×1.3 | 도착 맵 적 전체 |
| 전투 HP | 200 | 전투 엔티티 스폰 시 |
| 전투 공격력 | 45 | 전투 엔티티 스폰 시 |
| 처치 포인트 | 50 | 성장 포인트 |

### 구현 상태 (Phase 2-3c 완료)
- **DuskSpiderSystem**: Autoload. 시간 흐름 감지 → 스폰 → 이동 추적 → 도착 처리 → 전투 엔티티 스폰 → HUD 로딩
- **DuskSpiderNavigator**: BFS 경로탐색. StageSystem의 인접 그래프 기반
- **DuskSpiderEntity**: RefCounted 데이터 객체. 상태 머신 (IDLE → TRACKING → ARRIVED → DEFEATED)
- **DuskSpiderConfigData**: 외부 설정 리소스 (.tres). 모든 수치 외부화
- **DuskSpiderCombat**: BaseEnemy 확장 전투 엔티티. 플레이어 스테이지 도착 시 스폰
  - 잔류를 남기지 않음 (`leaves_residue = false`)
  - 처치 시 `EventBus.dusk_spider_defeated` 발신 → 논리 엔티티 정리
  - 씬: `DuskSpiderCombat.tscn` / 스탯: `dusk_spider_stats.tres`
- **도착 시 적 강화**: EnemyStats.reinforce()로 HP/ATK 배율 적용
- **도착 시 잔류 부활**: EventBus.residue_revival_requested 발신
- **시스템 간 통신**: EventBus.dusk_spider_spawned / dusk_spider_approached / dusk_spider_arrived / dusk_spider_defeated / enemy_reinforce_requested
- **접근 경고 HUD (Phase 2-3c)**: 우상단 DuskSpiderHud. 2맵 이내 접근 시 보라색 맥동, 1맵 시 긴급, 도착 시 플래시 연출. fallback ColorRect 사용.

### 미결 사항
- [ ] 땅거미 자체 공격 패턴
- [ ] 땅거미 전용 아트 리소스 (현재 fallback 사각형 사용)

---

## 4. 그림자 잔류

- 처치한 적의 잔여 그림자가 맵에 흔적으로 남음
- 평소 무해, 땅거미 도착 시 부활
- 정화 능력(중반 해금)으로 완전 제거 가능
- **정화 조건 (확정, Phase 2-4d 구현 완료)**:
  - 플레이어가 잔류 범위(40px) 내 + 등불 ON + 처치 시간대의 반대 시간대
  - 낮에 처치한 잔류 → 밤에 정화 / 밤에 처치한 잔류 → 낮에 정화
  - 조건 충족 시 자동 정화 (PurificationDetector)
- 시각적 구분: 낮 처치 = 보라빛 마커, 밤 처치 = 푸른빛 마커

### 부활 상태 (확정, Phase 2-3a 구현 완료)
- **HP 50%** — 원래보다 약함, 빠르게 처치 가능
- **공격력 150%** — 원래보다 강함, 맞으면 위험
- 유리대포 구조 → 긴박하지만 질질 끌리지 않음
- **부활 연출**: 잔류 마커 팽창(0.5초) + 발광 → 적으로 변환
- **재잔류 설정**: `revived_leaves_residue`로 on/off 가능 (기본값 off)
- **트리거**: `EventBus.residue_revival_requested(stage_id)` (땅거미 또는 외부)
- **자동 활성화**: 시간 흐름 중 부활 시 즉시 활성, 정지 시 DORMANT

### 구현 상태 (Phase 2-3a + 2-3b)
- **ResidueReviver**: EnemySystem 자식 컴포넌트, 부활 요청 처리
- **ShadowResidue.revive()**: 팽창 연출 후 BaseEnemy 재소환
- **BaseEnemy.setup_as_revived()**: HP/ATK 배율 적용, 재잔류 조건 분기
- **EnemyStats**: 부활 배율이 intensity와 독립 적용 (HP = base × intensity × revive_ratio)
- **EnemyStats.reinforce()**: 땅거미 도착 시 HP/ATK 강화 배율 적용 (×1.3)
- **디버그 R키 제거**: 땅거미 시스템 구현으로 수동 트리거 삭제 완료
- **수치 외부화**: `enemy_config.tres`에서 배율/재잔류 설정

### 미결 사항
- [ ] 잔류의 시각적 표현
- [ ] 부활 적의 시각적 구분 (틴트/글로우 등)
