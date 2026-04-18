# 시간이 멈춘 숲 — 전투 시스템

> 이 문서는 플레이어의 전투 동작, 공격 수단, 환경 활용을 정의한다.
> 스킬 시스템(SKILLS.md)과 적 시스템이 이 위에서 설계된다.

---

## 1. 전투 수단 개요

GDD에서 확정된 3가지 전투 수단:

| 수단 | 설명 |
|---|---|
| **A) 직접 공격** | 기본 공격 + 스킬로 적에게 직접 데미지 |
| **B) 그림자 약화** | 시간/빛 조절로 그림자를 축소하여 적 약화 (매크로) |
| **C) 환경 활용** | 맵의 환경 오브젝트로 빛/그림자 정밀 조작 (마이크로) |

- B, C는 핵심 로직 시스템(CORE_SYSTEMS.md)에서 설계 완료
- 이 문서에서는 **A(직접 공격)** 의 구체적 설계에 집중

---

## 2. 기본 공격 (확정 / Phase 1-6 구현 완료)

### 무기
- 검 (근접)

### 콤보 구조
- **4타 콤보** — 횡베기만 (좌우)
- 1~3타: 무속성 횡베기 (데미지 20)
- **4타(피니시)**: 최다 투자 스킬 트리의 속성 공격 (데미지 40)
  - 속성은 SkillSystem에서 동적 결정 (장착 스킬 경로 다수결: light/shadow/hybrid/neutral)
- 콤보를 끝까지 쳐야 속성 타격 발생 → 중간에 끊기면 무속성만
- 자원 소모 없음

### 콤보 상태 머신 (`player_combo.gd`)

```
IDLE → (공격 입력) → ATTACKING → (HitTimer 만료) → WINDOW → (입력 or WindowTimer 만료)
                                                        ├─ 입력 있음 → ATTACKING (다음 타)
                                                        └─ 입력 없음 → IDLE (콤보 리셋)
```

- **IDLE**: 공격 대기. 공격 입력 시 1타 시작.
- **ATTACKING**: HitTimer(`hit_duration`) 동안 히트박스 활성. 이 구간에 입력하면 버퍼링.
- **WINDOW**: WindowTimer(`combo_window`) 동안 다음 타 입력 대기. 입력 시 즉시 다음 타, 없으면 콤보 리셋.
- **4타 피니시 후**: 히트박스 비활성 → `combo_finished` 시그널 → IDLE 전이 → ResetTimer 후 콤보 초기화.

### 입력 버퍼링
- ATTACKING 중 공격 입력 → `_input_buffered = true`
- WINDOW 진입 시 버퍼 확인 → 있으면 자동 다음 타 실행

### 공격 중 이동
- 수평 속도를 `attack_movement_factor`(0.4 = 40%)로 감속
- DASH 상태는 제외 (감속 미적용)

### 공중 콤보
- JUMP/FALL 상태에서도 공격 가능 (제한 없음)

### 콤보 타이밍 수치 (combat_config.tres)

| 항목 | 값 | 설명 |
|---|---|---|
| `hit_duration` | 0.3s | 한 타의 공격 지속 시간 |
| `combo_window` | 0.35s | 다음 타 입력 대기 시간 |
| `combo_reset_time` | 0.5s | 피니시 후 콤보 초기화 대기 |

### 히트박스

- 플레이어 공격 히트박스는 `Area2D`로 동적 생성
- 크기: 36x24, 오프셋: (24, -14) — 방향에 따라 X 반전
- 콜리전 레이어: 8 (플레이어 공격)
- 비활성 시 `monitoring = false`, `monitorable = false`
- 히트박스에 메타데이터 부착: `hit_number`, `damage`, `is_finish`

### 미결 사항
- [ ] 피니시 타격의 속성별 차이 (빛: 관통? 그림자: 넉백? 혼합: 범위?)

---

## 3. 시간 정지 중 전투 동작

### 플레이어
- 시간 정지 중에도 공격 **입력 및 애니메이션은 정상 재생**
- 단, 히트박스가 활성화되지 않음 (`_enemies_active == false`이면 `monitoring/monitorable`을 켜지 않음)
- 결과: 공격 모션은 나오지만 데미지는 0

### 적
- 시간 정지 시 `EnemySystem.are_enemies_active() == false`
- 적 상태 머신이 DORMANT로 전환 → 모든 AI/이동 정지
- 적 히트박스(공격용): `monitoring = false`, `monitorable = false` — 플레이어에게 데미지 불가

---

## 4. HP / 피격 / 사망 / 리스폰

### HP 구조 (확정 / 구현 완료)
- **수치형** — 그림자 크기(20%~150%)에 따른 데미지 차이가 직접 체감됨
- `player_health.gd`에서 관리
- 초기 HP: 100.0 (`player_max_hp`)

### 피격 처리
1. 적 히트박스 또는 `enemy_projectile` 그룹 Area2D가 플레이어 허트박스에 진입
2. 무적 상태면 무시
3. 데미지 소스 판별:
   - 근접 히트박스: 적의 `Stats.get_attack()` 값 사용
   - 투사체(`enemy_projectile` 그룹): `area.get_meta("damage")` 값 사용 후 `area.on_hit()`로 소멸 처리 (Phase 2-2)
4. `health_changed` / `damage_received` 시그널 발신
5. HP가 0 이하 → 사망 처리 / HP가 남음 → 무적 + 넉백

### 무적 프레임
- 피격 후 0.5초간 무적 (`invincible_duration`)
- 무적 중 추가 피격 완전 무시

### 넉백
- 피격 시 적 반대 방향으로 넉백 적용
- `knockback_force`: 275.0 (수평)
- `knockback_up_force`: -150.0 (상방)
- `knockback_duration`: 0.35s
- 넉백 중 **플레이어 입력 차단** — 중력/마찰만 적용, 상태 머신/이동 계산 건너뜀

### 허트박스
- 플레이어 허트박스는 `Area2D`로 동적 생성
- 크기: 14x28, 오프셋: (0, -14)
- 콜리전 마스크: 16 (적 공격 히트박스 레이어)
- 사망 시 `monitoring = false`로 비활성화
- 리스폰 시 `monitoring = true`로 복원

### 회복 수단
- **아이템** — 전투 중 소모품 사용으로 회복 (미구현, 인벤토리 시스템 연동 필요)
- **자동 회복** — 시간이 멈춘 상태(STOPPED)에서만 약하게 회복 (✅ Phase 2-1 구현 완료)
  - 전투 중(시간 흐름 FLOWING/MANIPULATING): 자동 회복 없음
  - 전투 후(시간 정지 STOPPED): 소량 자동 회복 (1초 간격, 2.0 HP)
  - HP 만땅이면 타이머 미시작, 사망 시 타이머 정지
  - 수치는 `combat_config.tres`의 `auto_heal_amount`, `auto_heal_interval`로 조정

### 사망 처리
1. `player_died` 시그널 발신
2. 허트박스 비활성화
3. 플레이어 스프라이트 페이드아웃 (색상 `(0.3, 0.1, 0.1, 0.4)`, 0.5s)
4. CombatSystem의 `RespawnTimer` 시작 (`respawn_delay`: 1.0s)
5. 타이머 만료 시 `player_respawned` 시그널 발신

### 리스폰 처리
1. HP 전체 회복
2. 무적/넉백 상태 초기화
3. 마지막 스폰포인트 위치로 이동
4. 스프라이트 복원 (`modulate = Color.WHITE`)
5. 허트박스 재활성화

### 사망 페널티
- 없음 (확정)

---

## 5. 적 히트박스 / 피격 처리

### 적 히트박스 (공격용)
- `base_enemy.gd`에서 관리
- 기본 상태: `monitoring = false`, `monitorable = false`
- ATTACK 상태 진입 시만 양쪽 모두 `true`
- 상태 전환 시 `state_changed` 시그널로 자동 전환
- **행동 주입 (Phase 2-2)**: ATTACK 진입/종료 훅은 `AttackBehavior` 자식 컴포넌트로 위임. melee(근접 히트박스)/ranged(투사체 발사)/none 스크립트 중 `stats_data.attack_behavior`에 따라 런타임 주입.
  - melee: `hitbox_size` / `hitbox_offset` / `hitbox_active_duration` 값으로 `RectangleShape2D`를 크기/위치/지속시간 조정 (예: 나무 50x28 0.35s)
  - ranged: `projectile_telegraph` 선딜 후 `projectile_scene_path`의 투사체 스폰, 근접 히트박스는 비활성 유지
  - none: 훅 비어있음 (분열체, 부활체 등)

### 적 허트박스 (피격용)
- 플레이어 공격 히트박스(`player_attack` 그룹) 진입 감지
- 히트박스 메타데이터에서 `damage`, `is_finish` 읽어서 처리
- **방어 컴포넌트 (Phase 2-2)**: `take_damage()` 호출 시 `Defense` 자식 컴포넌트로 분기
  - `damage_reduction_flat`: 최종 데미지에서 감산 (최소 1 보장, 예: 바위 3 감산)
  - `hurt_resistance_chance`: 경직(HURT 상태 진입) 확률 (예: 바위 30% → 70% 경직 저항)
- 데미지 적용 후 `damage_dealt` 시그널 발신
- 사망 시 히트박스/허트박스 모두 비활성화 → **DeathBehavior 훅** → 잔류물 생성 → `queue_free()`
  - DeathBehavior: `stats_data.death_behavior`에 따라 `none`/`split` 스크립트 주입. `split`은 `spore_stats_path`의 분열체를 `spore_count`만큼 `spore_spread_radius` 범위에 스폰 (예: 꽃 2마리, 반경 20)
  - **재분열 방지**: 부활체(`_is_revived`) 또는 분열체(`is_spore`)는 death_behavior를 강제로 none 설정

---

## 6. 플로팅 데미지 숫자

`damage_number.gd` — 적 피격 시 머리 위에 숫자 표시

| 항목 | 일반 타격 | 피니시(4타) |
|---|---|---|
| 색상 | 흰색 `(1.0, 1.0, 1.0)` | 금색 `(1.0, 0.85, 0.3)` |
| 폰트 크기 | 8 | 10 |

- 위로 24px 떠오르며 0.6초간 페이드아웃 후 자동 제거
- 수평 랜덤 오프셋 (-6 ~ +6px) 적용
- 적의 `global_position + (0, -28)` 위치에 생성

---

## 7. 전투 HUD

`combat_hud.gd` — CombatSystem이 씬 로드 시 자동 인스턴스화

### HP 바
- ProgressBar로 표시 (0~100%)
- 라벨에 `"현재HP / 최대HP"` 수치 텍스트

### 콤보 인디케이터
- 4개의 ColorRect 도트
- 비활성: 반투명 회색 `(0.8, 0.8, 0.8, 0.3)`
- 활성(1~3타): 흰색 `(1.0, 1.0, 1.0, 1.0)`
- 피니시(4타): 금색 `(1.0, 0.85, 0.3, 1.0)`
- 콤보 리셋 시 전체 비활성으로 복귀

### 사망 오버레이
- 화면 전체 검은 오버레이 (`ColorRect`)
- 사망 시: 0.5s에 걸쳐 `alpha 0.6`으로 페이드인
- 텍스트 `"..."` 붉은색 `(0.8, 0.2, 0.2)` 페이드인 (0.3s)
- 리스폰 시: 오버레이 + 텍스트 동시 페이드아웃 (0.3s / 0.2s)

---

## 8. 이벤트 버스 시그널 (전투 관련)

| 시그널 | 파라미터 | 용도 |
|---|---|---|
| `combo_hit_landed` | `hit_number: int` | 콤보 N타 적중 시 |
| `combo_finished` | `attribute: String` | 4타 피니시 완료 시 |
| `combo_resetted` | — | 콤보 초기화 시 |
| `damage_dealt` | `target_id: int, amount: float` | 적에게 데미지 적용 시 |
| `damage_received` | `amount: float` | 플레이어 피격 시 |
| `health_changed` | `current_hp: float, max_hp: float` | HP 변동 시 |
| `player_died` | — | 플레이어 사망 시 |
| `player_respawned` | `position: Vector2` | 리스폰 완료 시 |
| `spawn_point_set` | `position: Vector2` | 스폰포인트 설정 시 |

---

## 9. 데이터 외부화 (combat_config.tres)

모든 전투 수치는 `data/combat/combat_config.tres` (CombatConfigData 리소스)에 집중.
스크립트에 하드코딩된 전투 수치 없음.

| 그룹 | 항목 | 기본값 |
|---|---|---|
| **Player HP** | `player_max_hp` | 100.0 |
| | `invincible_duration` | 0.5s |
| | `knockback_force` | 275.0 |
| | `knockback_up_force` | -150.0 |
| | `knockback_duration` | 0.35s |
| **Combo** | `combo_max_hits` | 4 |
| | `hit_duration` | 0.3s |
| | `combo_window` | 0.35s |
| | `combo_reset_time` | 0.5s |
| | `attack_movement_factor` | 0.4 |
| **Damage** | `base_damage` | 20.0 |
| | `finish_damage` | 40.0 |
| | `finish_attribute` | `"neutral"` |
| **Hitbox** | `hitbox_size` | (36, 24) |
| | `hitbox_offset` | (24, -14) |
| **Hurtbox** | `hurtbox_size` | (14, 28) |
| | `hurtbox_offset` | (0, -14) |
| **Auto Heal** | `auto_heal_amount` | 2.0 |
| | `auto_heal_interval` | 1.0s |
| **Respawn** | `respawn_delay` | 1.0s |

---

## 10. 파일 구조

```
src/systems/combat/
├── combat_system.gd          # Autoload — 설정 관리, 리스폰 타이머, HUD 로드
├── combat_calculator.gd       # 정적 데미지 계산 유틸리티
└── combat_config_data.gd      # CombatConfigData Resource 정의

src/entities/player/
├── player_combo.gd            # 콤보 상태 머신, 히트박스 생성/관리
├── player_health.gd           # HP, 무적, 넉백, 허트박스, 자동 회복 관리
└── player_skill.gd            # 스킬 입력/실행, 히트박스 전환

src/ui/hud/
├── combat_hud.gd              # HP바 + 콤보 인디케이터 + 사망 오버레이
└── skill_hud.gd               # 스킬 슬롯 HUD (4슬롯 + 쿨다운 오버레이)

src/ui/common/
└── damage_number.gd           # 플로팅 데미지 숫자

data/combat/
└── combat_config.tres          # 전투 수치 데이터
```

---

## 11. 이동 체계

### 기본 이동 (처음부터 사용 가능)
- 단일 속도 이동 (달리기)
- 2단 점프
- 대시

### 강화 이동 (진행에 따라 해금)
- 기본 이동의 강화판 → 잠금 해제 능력으로 별도 획득
- 빛/그림자 테마와 연결된 강화 (예: 빛 대시, 그림자 점프 등)
- 강화된 이동이 스테이지 잠금 구간 통과에 활용됨

### 미결 사항
- [ ] 강화 이동의 구체적 종류 및 해금 순서
- [ ] 이동공격 연계 방식
- [ ] 대시 속성 (무적 프레임 유무, 거리 등 — 프로토타입으로 결정)

---

## 12. 환경 오브젝트 활용

GDD에서 확정된 환경 오브젝트:

| 오브젝트 | 효과 | 전투 활용 | 구현 |
|---|---|---|---|
| 거울/수정 | 빛 분산 → 그림자 분열 | 강한 적 1체 → 약한 적(그림자 파편) 다수로 분할 | **Phase 2-5a 완료** |
| 렌즈(볼록) | 빛 집중 → 특정 그림자 극도로 축소 | 다수 중 하나만 골라 약화 | **Phase 2-5c 완료** |
| 차폐물(기둥, 벽) | 빛 차단 → 그림자 강제 생성/제거 | 투영 영역 내 적 강도 override (현재 CREATE만) | **Phase 2-5b 완료** |
| 반사 바닥(물, 얼음) | 아래에서도 빛 → 그림자 이중 약화 | 특정 지형 위에서 유리한 전투 | **Phase 2-5d 완료** |

### 상호작용 방식 (확정 — Phase 2-5a 베이스에서 구현됨)
- **수동 조작** — 시간 정지 상태(STOPPED)에서만 가능, 시간 흐름(FLOWING) 중에는 고정
- "세팅(정지) → 실행(흐름)" 리듬으로 전투와 퍼즐이 분리됨
- 입력: `interact_environment` (E키, 임시 키맵)
- 플레이어의 `EnvironmentInteractor` Area2D가 근접 오브젝트를 자동 타겟팅 (거리 기반)
- 조작은 단순하게:
  - 거울/수정: 상호작용 버튼 → 프리셋 각도로 회전 (4프리셋, 90°씩)
  - 렌즈: 상호작용 버튼 → 프리셋 각도로 회전 (4프리셋, 90°씩) — Phase 2-5c
  - 차폐물: 플레이어 반대 방향으로 1스텝 밀기(±16px, ±64px 클램프) — Phase 2-5b
  - 반사 바닥: 고정 지형 (조작 대상 아님)

### 거울 활용 메커니즘 (Phase 2-5a)
- **목적**: 위험 특성을 가진 적(공격력 높은 적, 광역 공격 적 등)을 무력화된 작은 스포어로 변환 → 리스크 감소가 1차 효익, 광역 콤보 처치 효율은 자연스럽게 따라옴
- **흐름**:
  1. STOPPED 중: 거울에 접근 → [E]로 부채꼴(60°/128px) 방향을 적이 들어 있는 영역으로 회전
  2. FLOWING 진입: 영향권 내 모든 적이 자동으로 분열 (1체 → 다수의 그림자 파편)
  3. 분열된 파편(`shard_spore_enemy.tres`)은 `attack_behavior="none"`이라 공격하지 않음 → 안전하게 처치 가능
- **분열 인프라 공용화**: 적 사망 분열(`death_behavior_split`)과 거울 분열이 `split_spawner.gd` 정적 헬퍼를 공유. `BaseEnemy.trigger_split(fallback, count, spread_radius)` public API로 외부에서 호출.
- **재분열 가드**: 부활체(`_is_revived=true`) 또는 스포어(`is_spore=true`)는 거울 영향권에 들어와도 무시 — 무한 분열 방지
- **드롭/잔류 차이**: `trigger_split()`은 전투 처치가 아니므로 드롭/잔류를 발생시키지 않음

### 렌즈 활용 메커니즘 (Phase 2-5c)
- **목적**: 다수의 적 중 특정 1체만 정밀 약화 → 차폐물이 "전체 난이도 연출"이라면 렌즈는 "단일 타겟 조정". 보스/엘리트 적을 일시 약화시켜 피니시 타이밍 잡는 용도로 설계.
- **흐름**:
  1. STOPPED 중: 렌즈에 접근 → [E]로 4프리셋(90°씩) 회전 — 좁은 집광 영역(48×24)을 목표 적에 겹치도록 조준
  2. 집광 영역에 들어간 적의 그림자 강도가 `focus_intensity(0.1)`로 상시 override — "극도로 약화"
  3. 영역 이탈 시 낮/밤 상태에 맞는 원래 강도로 복원 (차폐물과 동일 로직)
- **override 구조**:
  - `enemy.update_intensity(minf(현재, focus_intensity))` — min 병합으로 "더 약한 쪽 승" (차폐물 max 병합의 대칭)
  - `_process`에서 매 프레임 재적용 — EnemySystem 브로드캐스트 무효화 (차폐물과 동일)
  - 이탈 복원: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)`
- **거울과의 차이**: 거울은 FLOWING 진입 시 1회 트리거(분열), 렌즈는 STOPPED+FLOWING 상시 override. 또한 거울은 넓은 부채꼴(60°/128px), 렌즈는 좁은 집광 영역(48×24)으로 타겟팅 정밀도를 차별화.
- **차폐물과의 차이**: 투영 방향이 빛 방향과 독립 (렌즈는 프리셋 회전으로만 결정, 빛 각도 무관). 본체 물리 차단 없음 (광학 장치 특성).
- **재사용 인프라**: `environment_object.gd` 베이스 + `environment_influence_zone.gd`(enemy_entered/exited 시그널 추가) + `environment_prompt.gd` + `environment_highlight.gd` 공유

### 반사 바닥 활용 메커니즘 (Phase 2-5d)
- **목적**: 특정 지형 위에서 전투를 벌이면 그림자가 "아래에서 올라온 빛"으로 추가 약화 → 지형 자체가 플레이어 유리 조건. 차폐물/렌즈가 "플레이어가 세팅"이라면 반사 바닥은 "지형이 상시 제공".
- **흐름**:
  1. 정적/비상호작용 — `can_interact=false`, STOPPED 게이팅 없음, 회전/이동 없음
  2. 영역에 들어간 적의 그림자 강도가 `baseline × reflect_multiplier(0.5)`로 상시 override — "이중 약화"
  3. 영역 이탈 시 낮/밤 상태에 맞는 원래 강도로 복원
- **override 구조 (Cover/Lens와 다른 축)**:
  - Cover: `maxf(현재, 0.9)` 고정 강화 / Lens: `minf(현재, 0.1)` 고정 약화
  - **반사 바닥**: `clampf(baseline × 0.5, 0, 1)` — **multiplier 방식**. "이미 약한 그림자도 절반으로, 강한 그림자도 절반으로"
  - baseline: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)`
  - `_process`에서 매 프레임 재적용 (다른 환경 오브젝트와 동일 패턴)
- **다른 환경 오브젝트와 중첩**: 별도 병합 체계 없음 — 각자 `_process`가 독립 override 하므로 프레임 내 마지막 실행이 승리. 스테이지 디자인 책임으로 중첩 회피 (Phase 5 밸런싱 시 재검토).
- **플레이어 미영향**: 영역 Area2D는 mask 4(적만). 본체 StaticBody2D 없음 — 플레이어는 기존 Floor 위로 걷고, 시각적으로만 반사 바닥을 통과.
- **재사용 인프라**: `environment_object.gd` 베이스 + `environment_influence_zone.gd`(렌즈와 공용). Highlight/Prompt 노드 생략(비상호작용).

### 차폐물 활용 메커니즘 (Phase 2-5b)
- **목적**: 전투 중 적의 그림자 강도를 국소적으로 강제 → "낮에 짧은 그림자/밤에 긴 그림자" 같은 불리 지점을 플레이어가 연출 → 전투 난이도/피니시 속성 타이밍 조정
- **흐름**:
  1. STOPPED 중: 차폐물에 접근 → [E]로 플레이어 반대 방향 1스텝 밀기(±16px, ±64px 클램프)
  2. 차폐물 뒤쪽 직사각형 투영 영역(96×32, 낮=태양 반대 / 밤=등불 반대)에 들어간 적의 그림자 강도가 `block_intensity(0.9)`로 상시 override
  3. 영역 이탈 시 낮/밤 상태에 맞는 원래 강도로 복원
- **override 구조**:
  - CREATE 모드: `enemy.update_intensity(maxf(현재, block_intensity))` — max 병합으로 "더 강한 쪽 승"
  - `_process`에서 매 프레임 재적용 — EnemySystem 브로드캐스트가 덮어쓰는 것을 무효화
  - 이탈 복원: 낮=`EnemySystem.get_current_intensity()` / 밤+등불 ON=`ShadowSystem.get_intensity_at(enemy.global_position)`
- **투영 방향 갱신**: `EventBus.shadow_params_changed` 수신 시 회전만 갱신 (밤+등불 OFF면 각도 0으로 사실상 비활성)
- **BlockMode 자리 확보**: `BlockMode.REMOVE / BOTH` enum 정의. Phase 2-5b 구현 범위는 CREATE만, 나머지는 후속 Phase에서 오브젝트 배치 규격과 함께 결정
- **재사용 인프라**: 거울과 동일한 `environment_object.gd` 베이스 + `environment_prompt.gd` + `environment_highlight.gd` 공유. 투영 영역만 전용 `shadow_projection_zone.gd` 브리지 사용

### 미결 사항
- [ ] 오브젝트 배치 밀도 및 활용 빈도
- [ ] 차폐물 `BlockMode.REMOVE / BOTH` (현재 CREATE만)

---

## 13. 미구현 / 확장 예정

| 항목 | 상태 | 비고 |
|---|---|---|
| 피니시 속성 분기 (빛/그림자/혼합) | ✅ 구현 | SkillSystem.get_finish_attribute() 연동 (Phase 2-1) |
| HP 자동 회복 (시간 정지 중) | ✅ 구현 | STOPPED 상태에서 자동 회복 (Phase 2-1) |
| 속성별 데미지 배율 | ✅ 프레임워크 | CombatCalculator에 ATTRIBUTE_MULTIPLIERS 테이블 (전부 1.0, Phase 5 밸런싱에서 조정) |
| 스킬 슬롯 시스템 | ✅ 구현 | SkillSystem + 4슬롯 + 쿨다운 + HUD (Phase 2-1) |
| 아이템 회복 | 미구현 | 인벤토리 시스템 연동 필요 |
| 강화 이동 (빛 대시, 그림자 점프 등) | 미구현 | 성장/잠금 해제 시스템 |
| 환경 오브젝트 전투 활용 — 거울 | ✅ Phase 2-5a 완료 | EnvironmentObject 베이스 + Mirror + 분열 트리거 |
| 환경 오브젝트 전투 활용 — 차폐물 | ✅ Phase 2-5b 완료 | CoverData + ShadowProjectionZone + 강도 override(CREATE) + 매 프레임 재적용 |
| 환경 오브젝트 전투 활용 — 렌즈 | ✅ Phase 2-5c 완료 | LensData + FocusZone + 강도 override(min 병합, focus_intensity=0.1) + 4프리셋 회전 |
| 환경 오브젝트 전투 활용 — 반사 바닥 | ✅ Phase 2-5d 완료 | ReflectiveFloorData + InfluenceZone + baseline × reflect_multiplier(0.5, 이중 약화) + 정적/비상호작용 + _process 재적용 |
| HP 성장 곡선 | 미결 | 밸런싱 단계에서 결정 |
| **힛 플래시 (피격 시 화이트 플래시)** | 미구현 → Phase 3-7 Pass 2 | 전 Damageable 공통 shader. 피니시 속성별 색상 분기 (EFFECTS.md 선택지 #2) |
| **힛스톱 (피격 시 프리즈)** | 미구현 → Phase 3-7 Pass 2 | `Engine.time_scale` + 약/중/강/피니시 3~4단계. CombatSystem API로 노출 |
| **카메라 쉐이크 (trauma 기반)** | 미구현 → Phase 3-7 Pass 1/2 | 공격/피격/폭발 세기 분리. `add_trauma()` API |
| **데미지 넘버 팝업 재설계** | 부분 구현 → Phase 3-7 Pass 2 | 현재 있음(섹션 6). 크리티컬/피니시 속성별 색상·스케일 차별화 필요 |
| **혈흔/파편 파티클** | 미구현 → Phase 3-7 Pass 2 | GPUParticles2D. 적 타입별 색상 (나무=갈색, 바위=회색 등) |
| **슬래시 트레일 + 검광** | 미구현 → Phase 3-7 Pass 5c | 콤보 1~3타 Line2D, 피니시는 전용 스프라이트 |
| **피니시 컷인 (줌 + 슬로우 + 블랙바)** | 미구현 → Phase 3-7 Pass 5c | 보스/엘리트 마지막 일격 |
| 무적 깜빡임 | 미구현 | 피격 후 0.5s 무적 동안 modulate 점멸. 아트 불필요(코드만) |

> **이펙트 설계 전문**: `docs/EFFECTS.md` 참조. 구현 로드맵(섹션 6)과 아트 디렉션 선택지(섹션 5) 확인 필수.
