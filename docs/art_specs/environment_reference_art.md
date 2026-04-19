# 환경 오브젝트 교보재 (프로그래밍 아트)

> Pass 8 — Mirror · Lens · ReflectiveFloor · Cover 4종.
> Pass 9 — LightSensor 1종.
> 포털 교보재 패턴(`stage_portal_visual.gd`)과 동일 — `_draw()` 기반 + `sprite_path` fallback.

## 1. 대상 오브젝트

| 오브젝트 | 시각 스크립트 | 배치 위치 | 특징 |
|---|---|---|---|
| **Mirror** | `mirror_visual.gd` | `RotationPivot/Visual` | 다이아몬드 프레임 + 반사 빔(fan). 본체 24×40, 빔 128×128 |
| **Lens** | `lens_visual.gd` | `RotationPivot/Visual` | 12각 크리스탈 + 원뿔 수렴 빔 + 집광 영역. 크기 데이터 기반 |
| **ReflectiveFloor** | `reflective_floor_visual.gd` | `Visual` (루트 직속) | 수면 풀 + 잔물결 + 하이라이트 밴드. 크기 데이터 기반 |
| **Cover** | `cover_visual.gd` | `Body/Visual` | 석판 + 균열 + 이끼. 크기 데이터 기반 |
| **LightSensor** | `light_sensor_visual.gd` | `Visual` (Area2D 자식) | 32×32 룬 스톤 + 6개 룬 + 코어. 활성화 시 펄스 halo. LightSensorData의 `color_on`/`color_off` 사용 |
| **HiddenRevealer** | — (교보재 없음) | — | 순수 로직 노드. 본체가 시각 요소를 가지지 않고 target_node를 드러내는 역할만 함 |

## 2. 공통 구조 (포털 패턴 준수)

- 각 `*_visual.gd`는 `Node2D` 확장.
- `@export var sprite_path: String = ""` — PNG 교체용 경로. 설정 시 `_setup_sprite_fallback()`이 자식 `Sprite2D` 생성 후 `_draw()` 스킵.
- `_process(delta)`는 시간 누적 + `queue_redraw()` 호출 (sprite fallback 비활성 시에만).
- `_draw()`에서 여러 `_draw_*` 서브 함수로 분할 (빔/본체/하이라이트 등).

## 3. 데이터 기반 크기

**Mirror**는 상수 크기 (본체·빔 고정).
**Lens / ReflectiveFloor / Cover**는 부모 스크립트(`lens.gd` 등)의 `_ready()`에서 `_visual.configure(...)` 호출로 데이터 리소스 값 반영.

| 오브젝트 | `configure()` 시그니처 | 데이터 출처 |
|---|---|---|
| Lens | `(beam_length, body_size, focus_length, focus_width, beam_body_half)` | `LensData` |
| ReflectiveFloor | `(size: Vector2)` | `ReflectiveFloorData.body_size` |
| Cover | `(size: Vector2)` | `CoverData.body_size` |
| LightSensor | `configure(color_off, color_on)` + `set_active(bool)` | `LightSensorData.color_on/off` |

## 4. 애니메이션 / 상수

| 오브젝트 | 애니메이션 | 주기 |
|---|---|---|
| Mirror | 빔 알파 펄스 + 유리면 하이라이트 시프트 | 2.2s |
| Lens | 집광 영역 알파 펄스 + 크리스탈 하이라이트 시프트 | 2.6s |
| ReflectiveFloor | 잔물결(3개 순환) + 수면 밴드 웨이브 | 2.8s |
| Cover | 정적 (애니메이션 없음) | — |
| LightSensor | 활성화 시에만 halo·룬·코어 펄스. 비활성 시 정적 | 1.6s |

## 5. 픽셀아트 교체 시

1. `.ase` → `aseprite --batch --sheet` → PNG 1장 (단일 프레임 기본; 펄스 애니메이션 필요 시 태그 추가).
2. `assets/sprites/objects/{mirror|lens|reflective_floor|cover}/` 에 배치.
3. 인스펙터에서 `Visual.sprite_path` 에 `res://assets/sprites/objects/.../xxx.png` 지정.
4. 적용 즉시 `_draw()` 스킵, `Sprite2D` 교보재 대체.

## 6. 제거된 placeholder 노드

| 씬 | 제거된 노드 |
|---|---|
| `Mirror.tscn` | `RotationPivot/BeamVisual` (Polygon2D), `RotationPivot/MirrorBody` (Polygon2D) |
| `Lens.tscn` | `RotationPivot/BeamVisual`, `RotationPivot/LensBody` (Polygon2D), `RotationPivot/LensBorder` (Line2D), `RotationPivot/FocusZone/FocusVisual` (ColorRect) |
| `ReflectiveFloor.tscn` | `InfluenceZone/FloorVisual` (ColorRect) |
| `Cover.tscn` | `Body/BodyVisual` (ColorRect). `ShadowProjectionZone/ProjectionVisual` (그림자 표시기)는 유지 |
| `LightSensor.tscn` | `Visual` (ColorRect) → `Visual` (Node2D + `light_sensor_visual.gd`) 로 대체 |

## 7. 상호작용 / 콜리전 영향 없음

- 모든 `Area2D`, `CollisionShape2D`, `CollisionPolygon2D` 는 유지 — 물리/감지 로직 무변경.
- 부모 스크립트의 상호작용, override, 이벤트 시그널 로직 그대로 작동.
