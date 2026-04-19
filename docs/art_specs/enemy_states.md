# 적 상태 연출 교보재

> Phase 3-7 이펙트 Pass 2 선행 — 전투 피드백 기본형.
> 시스템: `src/entities/enemies/base/enemy_feedback.gd`

## 1. 효과 3종

| 상태 | 트리거 | 연출 | 길이 |
|---|---|---|---|
| **피격 (Hit)** | `Hurtbox.area_entered` — 플레이어 공격 접촉 | 흰색 오버레이 (`modulate = Color(2.5, 2.5, 2.5, 1)`) → 기본색으로 tween | 0.08s |
| **경직 (Stagger)** | `state_machine.state_changed` → `HURT` 진입 | X축 랜덤 오프셋 (±2.5px), 선형 감쇠 | 0.3s (HURT 상태 길이와 동일) |
| **사망 (Death)** | `stats_comp.died` 후 queue_free 직전 | `modulate.a` 1→0 + `scale` 1.0→0.6 동시 tween | 0.4s |

## 2. 픽셀아트 교체 시 주의

- 모든 효과는 `CharacterBody2D` 루트의 `modulate`/`scale`과 자식 `AnimatedSprite2D.position`에 적용 → 스프라이트를 얹어도 자동 반영.
- 프레임 기반 hurt/death 애니메이션을 추가하려면 `AnimatedSprite2D`의 `SpriteFrames`에 `hurt` / `dead` 태그 추가. `enemy_animation.gd`가 상태 이름으로 자동 재생.
- hurt/dead 애니메이션 총 길이가 위 수치(0.3s / 0.4s)와 맞지 않으면 `enemy_feedback.gd`의 상수를 조정하거나, 프레임 기반 쪽이 우선이면 피드백 비활성화 플래그 추가 고려.

## 3. 규격 (프레임 기반 교체용)

픽셀아트 시트 권장 규격 (ART_RESOURCE_LIST #105~110 연동):

| 애니메이션 | 프레임 수 | FPS | 루프 | 비고 |
|---|---|---|---|---|
| `idle` | 4 | 6 | 반복 | 기본 대기 |
| `walk` | 6 | 10 | 반복 | PATROL 상태 |
| `run` | 6 | 12 | 반복 | CHASE 상태 |
| `attack` | 5 | 12 | 1회 | ATTACK 상태 |
| `hurt` | 3 | 15 | 1회 | HURT 상태 (0.2s 내 재생 권장) |
| `dead` | 6 | 15 | 1회 | DEAD 상태 (0.4s 내 재생 권장) |

캔버스는 적 타입별로 상이하나 기본은 32×32. 거대 적(stage 1-B 보스)은 별도 명세.

## 4. 통합 경로

픽셀아트 완성 시:
1. `.ase` → `aseprite --batch --sheet` → PNG + JSON
2. `SpriteFrames` 리소스 생성 후 애니메이션 태그별 프레임 지정
3. `EnemyStatsData`의 `sprite_frames_path` (추후 추가 예정 필드)에 연결
4. `enemy_animation.gd`가 fallback ColorRect 대신 자동으로 스프라이트 사용
5. 본 교보재 연출(피격/경직/사망)은 그대로 유지

## 5. 튜닝 포인트

- 플래시가 너무 강하면 `FLASH_COLOR` 값 낮춤 (기본 2.5배). 색상 톤을 주려면 흰색 대신 옅은 황색/청색 시도.
- 흔들기 강도는 `SHAKE_AMPLITUDE`. 거대 적은 더 크게, 작은 적은 줄일 것.
- 디졸브 대신 모자이크/파티클 터짐을 원하면 `play_death_dissolve` 내부만 교체. 호출부는 동일.
