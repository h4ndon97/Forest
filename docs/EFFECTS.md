# 시간이 멈춘 숲 — 이펙트 및 연출 설계

> 이 문서는 게임의 시각 연출(전투 피드백, 환경 분위기, 시간 정지 연출, UI 이펙트, 카메라 효과)의 설계를 정의한다.
> 레퍼런스 게임 조사, Godot 4.x 구현 기법, 프로젝트 맞춤 추천, 구현 로드맵을 포함한다.
>
> **관련 문서**: COMBAT.md (전투), ART_PIPELINE.md (아트 규격), ART_RESOURCE_LIST.md (에셋 목록), CORE_SYSTEMS.md (시간/그림자 시스템)
>
> **UI 이펙트 상위 문서**: [art_specs/ui_design_master.md](art_specs/ui_design_master.md) 섹션 H (피드백·트랜지션) 참조.
> 본 문서는 구현 기법/Pass 구성/에셋을, 상위 문서는 UI 카테고리 간 정합성과 컨셉 방향을 담당한다.
> 두 문서 간 모순 발견 시 상위 문서의 컨셉 결정이 우선.

---

## 1. 목적 및 방향성

본 프로젝트는 **2D 픽셀아트 메트로배니아 + 시간 정지 메카닉**을 핵심으로 한다. 이펙트 시스템은 다음 세 가지를 달성해야 한다.

1. **시간 정지**의 시각적 아이덴티티 확립 — 플레이어가 시간을 멈추는 순간이 즉시 인지 가능해야 함
2. **전투 피드백 강화** — 픽셀아트의 단순한 모션을 셰이더/파티클/카메라로 보강하여 타격감 확보
3. **땅거미(Dusk Spider) 공포 연출** — 추적자의 근접을 다층적 경고로 전달

---

## 2. 레퍼런스 게임 분석

조사한 레퍼런스 중 이 프로젝트에 가장 영향력 있는 7개.

| 게임 | 시그니처 연출 | 이 프로젝트 접점 |
|---|---|---|
| **Katana Zero** | Chronos 슬로우모션 + 블루 필터 + 회상 잔상 | **시간 정지 메카닉의 1순위 레퍼런스** |
| **Hollow Knight** | 원형 Soul 미터, 피격 시 프리즈, 앰비언트 파티클이 살아있는 월드 | 다크 메트로배니아 HUD 미니멀리즘 |
| **Dead Cells** | 강한 힛스톱 + 카메라 쉐이크 + 데미지 넘버 박히는 타격감 | 전투 "쫀맛"의 기준점 |
| **Blasphemous 1/2** | 고해상도 픽셀아트, 보스 처형 컷인, 묵직한 피니시 | 피니시 속성 시스템과 직결 |
| **Hyper Light Drifter** | 플랫 컬러 + 비네트/그라데이션 오버레이, 네온 Light2D | 라이팅과 색감 |
| **Ender Lilies / Magnolia** | 서정적 파티클, 깔끔한 고딕 UI, 타이프라이터 대화 | UI/메뉴 감성 |
| **Celeste** | 스쿼시&스트레치, 머리카락 색 상태 표시, 대시 쉐이크 | 캐릭터 모션 juice |
| **INARI** (미출시, 스팀 페이지) | 발광 이펙트의 **코어/할로 2레이어 분리** + HDR 블룸 + 방사형 라인 버스트, 대기 원근·실루엣 배경 | **전투·시간 정지 해제 이펙트의 셰이더/발광 기법 레퍼런스** (→ [effects_pass3_step4_inari_ref.md](art_specs/effects_pass3_step4_inari_ref.md)) |

---

## 3. 카테고리별 기법 카탈로그 (Godot 4.x)

각 기법은 Godot 4.x 기준으로 구현 난이도를 표기한다.
- **[쉬움]** 기본 노드/Tween/AnimationPlayer로 즉시 구현 가능
- **[중간]** 간단한 Shader나 Particle 설정 필요
- **[어려움]** 복잡한 셰이더 / 서브뷰포트 / 별도 에셋 필요

### A. 전투/스킬 이펙트

| 기법 | 레퍼런스 | 난이도 | Godot 4 구현 방식 |
|---|---|---|---|
| 화이트 힛 플래시 (2~4 프레임) | Hollow Knight, Dead Cells | **[쉬움]** | `canvas_item` shader에 `flash_amount` uniform. `mix(color.rgb, flash_color.rgb, flash_modifier)`. Tween으로 0→1→0. 약 5줄 |
| 힛스톱 (피격 시 프리즈 6~10 프레임) | Hollow Knight, Dead Cells | **[쉬움]** | `Engine.time_scale = 0.0` + `await get_tree().create_timer(0.08, true, false, true).timeout`. `ignore_time_scale=true` 사용 |
| 카메라 쉐이크 (트라우마 기반) | Celeste, Dead Cells | **[쉬움]** | Camera2D.offset에 `randf_range` + trauma^2 감쇠. `trauma` 변수로 강도 누적 |
| 검광/슬래시 트레일 | Katana Zero, Hollow Knight | **[중간]** | (1) Line2D + 포인트 배열 shift (2) AnimationPlayer로 슬래시 스프라이트 단발 (3) particle-based trail |
| 잔상 / Afterimage | Katana Zero, Dead Cells(대시) | **[중간]** | 플레이어 Sprite2D를 `.duplicate()`로 같은 위치 배치 → Tween으로 modulate.a 0.5→0. 0.05초마다 스폰 |
| 데미지 넘버 팝업 | Dead Cells | **[쉬움]** | Label + Tween (position.y -16, modulate.a 1→0, 0.6초). 크리티컬은 scale 1.4 + 색상 변경 |
| 혈흔/파편 파티클 | Dead Cells, Blasphemous | **[쉬움]** | GPUParticles2D one_shot=true. Direction + 중력 + 짧은 lifetime(0.3s) |
| 피니시 컷인 + 줌 | Blasphemous 2 | **[중간]** | Camera2D.zoom Tween + time_scale 0.2 + CanvasLayer 오버레이(블랙바 2줄) |
| 넉백 + 스쿼시 | Celeste | **[쉬움]** | Sprite2D.scale을 Tween으로 (1.2, 0.8) → (1, 1) 복귀 |

### B. 환경/분위기

| 기법 | 레퍼런스 | 난이도 | Godot 4 구현 방식 |
|---|---|---|---|
| 전역 어둠 + 등불 | Hollow Knight | **[쉬움]** | CanvasModulate + PointLight2D (기존 설계 활용) |
| 오클루전 기반 다이나믹 그림자 | Hyper Light Drifter | **[중간]** | LightOccluder2D + TileMap Occlusion layer. 성능/룩 주의 |
| 앰비언트 파티클 (먼지, 낙엽, 반딧불) | Hollow Knight, Ender Lilies | **[쉬움]** | GPUParticles2D를 카메라 자식으로. lifetime 8s, 낮은 initial_velocity, 약한 중력 |
| 패럴랙스 | 전 메트로배니아 | **[쉬움]** | ParallaxBackground + ParallaxLayer 3~5층 |
| 비네트 오버레이 | Hyper Light Drifter | **[쉬움]** | CanvasLayer 최상단 TextureRect(원형 그라데이션) + blend=Multiply |
| 안개/빛 번짐 | Ender Magnolia | **[중간]** | PointLight2D의 texture를 부드러운 그라데이션 + blend=Add, energy 0.5 |

### C. 시간 조작 / 땅거미 (프로젝트 핵심)

| 기법 | 레퍼런스 | 난이도 | Godot 4 구현 방식 |
|---|---|---|---|
| **시간 정지 전역 필터** | Katana Zero | **[중간]** | 전역 CanvasLayer ColorRect + canvas_item shader. `COLOR.rgb = mix(gray, COLOR.rgb, 0.3); COLOR.rgb += vec3(-0.05, 0, 0.1);`. Tween으로 weight 페이드 |
| **프레임 고정형 적 정지** | Braid, Superhot | **[쉬움]** | 적 AnimationPlayer.speed_scale=0, 물리 process_mode=DISABLED. 재개 시 역순 |
| **정지 상태 속 숨결 파티클** (플레이어 주변만 움직임) | Katana Zero | **[쉬움]** | 플레이어 자식 GPUParticles2D만 `speed_scale=1`, 나머지는 0 |
| **땅거미 접근 — 비네트 붉어짐** | Hollow Knight 어둠 구역 | **[쉬움]** | 거리 ratio로 비네트 modulate `Color(1, 0.3, 0.3, ratio)` 보간 |
| **땅거미 접근 — 화면 경계 떨림** | STALKER 근접 경고 | **[쉬움]** | 비네트 TextureRect position에 저진폭 shake (±1px) |
| **땅거미 근접 스크린 왜곡** | Blasphemous 환상 구간 | **[어려움]** | 스크린 읽기 shader + SCREEN_TEXTURE UV에 사인 오프셋 |
| **어둠 속 실루엣** | Hollow Knight Shade | **[중간]** | 땅거미 스프라이트 전용 shader: 검정 덮어쓰기 + 가장자리만 붉게 (에지 디텍트) |

### D. UI/HUD 이펙트

| 기법 | 레퍼런스 | 난이도 | Godot 4 구현 방식 |
|---|---|---|---|
| **딜레이드 체력바** (피격 시 흰 바가 뒤따라 감소) | JRPG, Blasphemous | **[쉬움]** | ProgressBar 2개 겹치기. 앞: 즉시, 뒤: 0.3s 지연 Tween |
| **원형 리소스 미터** (Soul 스타일) | Hollow Knight | **[중간]** | Control + `_draw()` 또는 TextureProgressBar radial 모드. 흔들리는 액체는 shader |
| **체력 크랙 오버레이** (빈사) | Hollow Knight | **[쉬움]** | CanvasLayer TextureRect + modulate.a = 1 - hp_ratio |
| **타이프라이터 대화** | Ender Lilies, Celeste | **[쉬움]** | RichTextLabel.visible_ratio를 Tween 0→1 |
| **아이템 획득 팝업** | Hollow Knight | **[쉬움]** | Label 슬라이드 인 + 아이콘 회전 등장 |
| **메뉴 전환 디졸브** | Ender Magnolia | **[중간]** | ColorRect + dissolve shader (노이즈 threshold) |
| **레벨업 플래시** | Dead Cells | **[쉬움]** | 전체 CanvasLayer TextureRect 페이드 + 배경 파티클 |
| **위험 경계 펄스** (땅거미) | Dead Souls류 | **[쉬움]** | 화면 4변 그라데이션 4개 + sin(time) modulate |

### E. 카메라 효과

| 기법 | 레퍼런스 | 난이도 | Godot 4 구현 방식 |
|---|---|---|---|
| 쉐이크 (공격/피격/폭발 세기 분리) | Dead Cells | **[쉬움]** | 단일 `add_trauma(0.3)` API, trauma^2로 offset |
| 줌 (피니시, 보스 등장) | Blasphemous | **[쉬움]** | Camera2D.zoom Tween EASE_OUT |
| 화면 플래시 | Celeste 대시 | **[쉬움]** | 1프레임 흰 ColorRect + Tween 알파 0 |
| 리드 카메라 (이동 방향 선반영) | Hollow Knight | **[중간]** | Camera2D.offset을 velocity 방향으로 lerp |

---

## 4. 프로젝트 맞춤 추천 Top 12

### Tier S (반드시)

1. **시간 정지 전역 포스트프로세스 필터** — Katana Zero Chronos 스타일. 채도 낮춤 + 청백색 하이라이트. 프로젝트 아이덴티티의 핵심
2. **힛스톱 + 카메라 쉐이크 3단계** — 약/중/강/피니시별 차등. 한 번 구현이면 모든 전투가 개선됨
3. **땅거미 접근 3단계 경고** — 거리별 비네트 색상 → 경계 떨림 → 근접 시 화면 왜곡. Phase 2-3c와 자연스럽게 통합
4. **화이트 힛 플래시** — 모든 Damageable 공통. 5줄 셰이더로 전투 피드백 2배

### Tier A (강력 추천)

5. **데미지 넘버 팝업 차별화** — 일반(흰/소), 크리티컬(노랑/대), 피니시(속성색/대 + 쉐이크)
6. **딜레이드 체력바 + 빈사 크랙** — Blasphemous/Hollow Knight 혼합
7. **슬래시 트레일 + 검광** — 기본 공격 Line2D, 피니시는 전용 스프라이트
8. **앰비언트 파티클** — 시간대/스테이지별 프리셋. 숲 분위기 핵심

### Tier B (여유 있을 때)

9. **시간 정지 해제 시 잔상 + 블루 파티클 펑**
10. **피니시 컷인 (줌 + 슬로우 + 블랙바)** — 보스/엘리트 마지막 일격
11. **비네트 + 패럴랙스 5층** — 설치만 해도 모든 스테이지 이득
12. **타이프라이터 대화창 + 선택지 디졸브**

---

## 5. 아트 디렉션 선택지 (D7 — 결정 완료 2026-04-19)

> **정책**: 아래 결정은 **잠정(provisional)**. 실제 아트 제작 중 감각이 맞지 않으면 언제든 수정 가능 (UI 설계 결정 가변성 원칙).
> 코드/.tres 수정 범위는 Pass 1 프레임워크가 이미 외부화해 두었으므로 미미함.

1. **시간 정지 화면 톤** — ✅ **(C) 세피아 — 화면 전체 균일** (2026-04-19 재조정, Pass 3 Step 1 사용자 체감 검증)
   - 선택 근거: 프로젝트 서사("선조의 시간 정지 = 과거의 무게")와 직접 공명. 과거/기억의 톤으로 시간 정지 = 봉인된 시대의 은유.
   - **재조정 내역 (2026-04-19)**: 원안은 "주변부만 색상 유지(edge vignette)" 해석이었으나 Pass 3 Step 1 사용자 시각 검증 결과 "화면 전체가 덮여야 자연스러움" 판정. 중앙 원형만 세피아인 상태가 "터널 시야"처럼 보여 몰입감 저하. → `edge_mask_radius` / `edge_softness` uniform 제거, `mix(original, sepia, weight)` 균일 적용.
   - 구현: Pass 3 Step 1에서 `time_stop_sepia.gdshader` 신규. weight Tween은 Pass 3 Step 2에서 추가.
   - 대안(보류): (A) 블루 틴트는 움직임 강조 톤이라 "정지"보다 "느려짐", (B) 청백색 단색은 레퍼런스 안전 선택.

2. **힛 플래시 색상** — ✅ **(B) 피니시 속성별 분기**
   - 매핑: `light` = 흰색 `Color(2.5, 2.5, 2.5)` / `shadow` = 보라 `#8B2FC6` HDR / `hybrid` = 금 `#F2CC66` HDR.
   - 구현: `EffectsSystem.get_finish_color(attribute: String)` API는 Pass 1에 이미 노출. Pass 2에서 공격 실행부와 연결만 하면 됨.
   - 기본 피격(비-피니시)은 흰색 유지 — 피니시 순간의 "한 방" 연출이 시각적으로 두드러지도록.

3. **땅거미 접근 경고 색** — ✅ **(C) 거리별 보간: 먼=보라 → 근접=빨강**
   - 톤: 먼거리 `#8B2FC6` (그림자 왕가 팔레트 = 서사적 정체성) → 근접 시 `Color(1.0, 0.2, 0.2)` 보간.
   - 구현: Pass 4에서 비네트 `modulate = lerp(purple, red, distance_ratio)`.
   - 효과: 서사(그림자 계보 위협)와 본능적 공포(빨강) 둘 다 획득.

4. **데미지 넘버 스타일** — ✅ **(A) 비트맵 픽셀 폰트**
   - 폰트: 기존 Galmuri11 재사용 (프로젝트 전 UI 일관성).
   - 차별화: 일반=흰/소(12px 상당), 크리티컬=노랑/대(14px, scale 1.4 Tween), 피니시=속성색(§2)/대 + 쉐이크.
   - 구현: Label + LabelSettings(Galmuri11) + Tween. 아웃라인은 shadow offset 1px.

5. **앰비언트 파티클** — ✅ **혼합: 낮=꽃가루(흰), 밤=반딧불(녹색 점광)**
   - 낮 (DAY/DUSK): 흰 꽃가루 `Color(0.95, 0.95, 0.9, 0.7)`, lifetime 8s, 낮은 gravity, 바람 벡터.
   - 밤 (NIGHT): 녹색 반딧불 `Color(0.4, 1.0, 0.4, 0.9)`, lifetime 6s, 부유 운동(sin 오프셋), 약한 glow(PointLight2D 자식).
   - 전환: TimeSystem의 시간대 시그널 구독 → GPUParticles2D `emitting` 토글 + Tween 페이드.
   - 구현: Pass 5에서 카메라 자식 GPUParticles2D 2종 프리셋.

6. **HUD 체력 표시 형태** — ✅ **(C) 구슬/pip 아이콘**
   - 핵심 심볼: 횃불 불씨 pip (UI 이중 축 — 빛 모티프 핵심 심볼).
   - 레이아웃: 가로 나열, HP당 1 pip, 피격 시 1개씩 꺼짐(페이드+축소 Tween). 빈사(1~2 pip) 시 붉은 맥동(0.8s).
   - 구현: Pass 5 UI 폴리시 단계. `src/ui/hud/` 기존 player_hud 재구성.
   - 대안(보류): (A) 가로 바는 "계기판"화되어 빛 모티프 약화, (B) 원형 미터는 Hollow Knight Soul과 직접 비교 우려.

---

## 6. 구현 로드맵

> **정책 결정 (2026-04-17)**: 공식 로드맵(DEVELOPMENT_PLAN.md) 준수. 이펙트 작업은 Phase 3-7에서 1구역 아트 본격 제작과 함께 일괄 진행한다.
>
> **근거**: Phase 2는 "시스템 프레임워크" 단계. 이펙트는 시각 폴리시 영역이므로 아트 확정(1구역 타일/캐릭터/UI) 이후 진행해야 재작업 비용이 없다. EFFECTS.md는 Phase 3-7 착수 시 설계 근거로 사용한다.

### Phase 2 잔여 작업 (이펙트 미포함)
- **2-5 환경 오브젝트** (거울/수정/렌즈/차폐물/반사 바닥) — 이펙트 없이 기능 우선

### Phase 3-7 (1구역 아트 적용) — 이펙트 작업 본진

Phase 3-1~3-6 구현이 완료된 뒤, 1구역 아트 에셋 제작과 함께 다음 5개 패스로 진행.

#### Pass 1. 기반 프레임워크 (아트 없이 구축 가능)
- **EffectsSystem Autoload** — 공통 API (`request_hit_flash`, `request_shake`, `request_hitstop`)
- **OverlaySystem Autoload** — 전역 CanvasLayer 비네트/포스트프로세스 관리
- **카메라 쉐이크** — trauma^2 기반, `add_trauma()` API
- **힛 플래시 shader** — 모든 Damageable에 공통 적용 (5줄 canvas_item)
- **힛스톱 유틸리티** — `Engine.time_scale` + ignore_time_scale 타이머
- **데이터 외부화** — `data/effects/effects_config.tres`

#### Pass 2. 전투 타격감
- 힛 플래시 색상 (피니시 속성별 분기 or 흰색 단일 — 아트 디렉션 #2)
- 카메라 쉐이크 세기 (약/중/강/피니시 4단계)
- 힛스톱 프레임 (일반/크리티컬/피니시)
- 데미지 넘버 재설계 (크리티컬/피니시 차별화 — 아트 디렉션 #4)
- 혈흔/파편 GPUParticles2D (적 타입별 색)

#### Pass 3. 시간 정지 연출 (프로젝트 아이덴티티)
- **Step 1** ✅ 완료 (2026-04-19): 전역 포스트프로세스 shader (세피아 균일 — 아트 디렉션 #1 재조정) + `EffectsTimeStop` 헬퍼(apply_instant) + 디버그 키 F12 토글
- **Step 2** ✅ 완료 (2026-04-19): EventBus 구독(`time_flow_started/stopped`) → `apply_transition` weight 0↔target Tween (0.30s, `set_ignore_time_scale(true)`, `_weight_tween.kill()` 재진입 안전). F12 디버그도 Tween 경로로 전환(시각 미리보기 전용, TimeSystem 상태 비오염)
- **Step 3** ✅ 완료 (2026-04-19): `EffectsFreezable` 헬퍼 신규 — `EventBus.time_flow_stopped/started` 구독 → `get_tree().call_group("freezable_particles", "set", "speed_scale", 0.0/1.0)`. Player.tscn에 `BreathParticles` GPUParticles2D 추가(그룹 비가입, speed_scale=1 고정, 위치 `(4,-28)`, process_material·GradientTexture 모두 scene sub_resource로 베이킹). F12 디버그가 셰이더 Tween + 그룹 토글 동시 호출. 현재 `freezable_particles` 멤버 0개(Pass 5 앰비언트 파티클 합류 시 자동 편입)
- **Step 4** ✅ 완료 (2026-04-20): `EffectsAfterimage` 범용 RefCounted 헬퍼 신규(Sprite2D/AnimatedSprite2D 현 프레임을 Sprite2D 복제본으로 스폰, `SceneTreeTimer(ignore_time_scale=true)` 스케줄). `EffectsSystem.request_afterimage(source, count?, interval?, fade?)` API. `EffectsTimeStop.apply_transition(on=false)` 경로에 `_trigger_release_fx()` 훅 — 블루 펄스(`request_screen_flash`) + Player 그룹 검색 후 잔상. blue_pulse_color B채널 LDR 클램프(ColorRect 알파 페이드 기반). Light Dash 잔상 연결은 범위 밖 — 헬퍼만 범용 API로 설계됨
  - **시각 레퍼런스**: INARI 전투 이펙트의 코어/할로 2레이어 + 방사형 버스트 구조 → 컬러만 블루 계열로 스왑. Step 4에서는 최소안(블루 펄스 + 잔상)만 적용, HDR 블룸 베이스라인·방사형 burst는 **Pass 5로 이월**(1구역 아트 확정 후 튜닝, 피니시 컷인과 기법 공유). 상세: [effects_pass3_step4_inari_ref.md](art_specs/effects_pass3_step4_inari_ref.md)

#### Pass 4. 땅거미 공포 연출
- 거리 기반 비네트 색/알파 보간 (아트 디렉션 #3)
- 근접 화면 경계 셰이크
- (선택) SCREEN_TEXTURE 왜곡 shader

#### Pass 5. UI/환경 폴리시
- 딜레이드 체력바, 빈사 크랙 오버레이
- 아이템 획득 팝업, 타이프라이터 대화창, 메뉴 디졸브
- 슬래시 트레일 (기본 Line2D + 피니시 스프라이트)
- 앰비언트 파티클 (시간대/스테이지별 프리셋 — 아트 디렉션 #5)
- 패럴랙스 5층 템플릿
- 피니시 컷인 (줌 + 슬로우 + 블랙바 — 보스/엘리트 전용)

### Phase 5-2 (폴리싱) — 최종 리비전
- 2~5구역별 이펙트 색감/세기 조정
- 보스전 전용 연출 추가
- 성능 최적화 (파티클 수, shader 비용)
- 접근성 옵션 (쉐이크 세기 조절, 포스트프로세스 ON/OFF)

### 병렬 진행 가능성
Pass 1(프레임워크)은 아트가 필요 없으므로, 1구역 아트 제작 대기 중 먼저 구축해두면 아트 에셋 들어올 때 즉시 연동 가능. 단 CLAUDE.md 원칙상 설계 문서 선행 → Architect 에이전트 호출 필수.

---

## 7. 아키텍처 원칙 (CLAUDE.md 준수)

- 이펙트 관련 공통 시스템은 `src/systems/effects/`에 Autoload로 집중 (`EffectsSystem`)
- 전역 포스트프로세스/비네트 오버레이는 CanvasLayer Autoload로 별도 분리 (`OverlaySystem`)
- 카메라 쉐이크 API는 CameraSystem 또는 기존 카메라 컨트롤러에 trauma 기반 API 추가
- 시스템 간 통신은 EventBus 시그널 (`screen_shake_requested`, `hit_flash_requested`, `time_stop_started/ended`)
- 수치는 `data/effects/effects_config.tres`에 집중

---

## 8. 참고 자료 (Sources)

### 게임 분석
- [Juice It Or Lose It — GDC Vault](https://www.gdcvault.com/play/1016487/juice-it-or-lose)
- [Don't Juice It or Lose It — GDC Vault](https://gdcvault.com/play/1020861/Don-t-Juice-It-or)
- [Designing Game Feel — Pichlmair & Johansen](https://arxiv.org/pdf/2011.09201)
- [Getting Hit Freeze Frame — Dead Cells](https://steamcommunity.com/app/588650/discussions/0/1291817208488058582/)
- [Katana Zero: Pixel Art Platformer/Slasher — 80.lv](https://80.lv/articles/katana-zero-pixel-art-platformerslasher)
- [Hollow Knight Art — PC Gamer](https://www.pcgamer.com/hollow-knights-charming-art-sets-the-bar-for-hand-drawn-games/)
- [Visual Design of Hollow Knight — Mechanics of Magic](https://mechanicsofmagic.com/2023/04/18/visual-design-of-games-hollow-knight/)
- [Game UI Database — Hollow Knight](https://www.gameuidatabase.com/gameData.php?id=113)
- [Game UI Database — Ender Lilies](https://www.gameuidatabase.com/gameData.php?id=1193)
- [Blasphemous Pixel Art — Game Anim](https://www.gameanim.com/2021/02/19/blasphemous-pixel-art-animation-time-lapses/)
- [Art Direction of Hyper Light Drifter](http://idrawwearinghats.blogspot.com/2014/04/art-direction-analysis-of-hyper-light.html)
- [Hyper Light Drifter UI Breakdown — Medium](https://medium.com/the-space-ape-games-experience/hyper-light-drifter-ui-breakdown-c2d9cfe0a192)

### Godot 4 기술 자료
- [Hit Flash Effect Shader — Godot Shaders](https://godotshaders.com/shader/hit-flash-effect-shader/)
- [Flash Shader — Godot Shaders](https://godotshaders.com/shader/flash-shader/)
- [Godot 4 Essential 2D Effects Shader Pack — Hollow Pixel](https://hollow-pixel.itch.io/godot-4-essential-2d-effects-free-shader-pack)
- [Custom post-processing — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/custom_postprocessing.html)
- [Screen-reading shaders — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
- [2D lights and shadows — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html)
- [GPUParticles2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html)
- [Godot Trail System — GitHub](https://github.com/OBKF/Godot-Trail-System)
- [Sprite After-image — Godot Forum](https://forum.godotengine.org/t/sprite-after-image-in-2d-game/78758)

---

## 9. 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-17 | 초안 작성. 레퍼런스 분석 + Top 12 + 로드맵 정의. Phase 2-3c 진입 전 기준 |
| 2026-04-19 | Pass 1 (프레임워크) 구현 완료 — EffectsSystem/OverlaySystem Autoload + 카메라 쉐이크(trauma²) + 힛플래시 셰이더 + 힛스톱 + effects_config.tres. 디버그 키 F6~F9. Damageable 3건(플레이어/적/보스) 연동. D7 6가지 디렉션 결정은 Pass 2에서 진행 |
| 2026-04-19 | **D7 6가지 아트 디렉션 결정 완료** (§5 갱신). ①세피아 + 주변부 색상 유지, ②피니시 속성별 힛플래시(light=흰/shadow=보라/hybrid=금), ③땅거미 경고 보라→빨강 보간, ④Galmuri11 비트맵 데미지 넘버, ⑤낮=꽃가루/밤=반딧불 혼합, ⑥HP pip(횃불 불씨) 아이콘. 동시에 `effects_config`에서 `finish_color_fire`/`finish_color_dark` → `finish_color_hybrid`/`finish_color_shadow`로 네이밍 정정 (프로젝트 속성 체계 `light`/`shadow`/`hybrid`와 일치) |
| 2026-04-19 | Pass 2 Step 1 (연결 작업) — ① 피니시 속성 passthrough 체인 구축: `player_combo` 히트박스 메타에 `finish_attribute` 추가 → `base_enemy`/`boss_weak_point`/`base_boss.apply_player_hit()` 시그니처 확장 → 피니시 시 `EffectsSystem.get_finish_color(attr)`로 힛플래시 색 override. `enemy_feedback.play_hit_flash(color_override)` 파라미터 추가. ② enemy 피니시 쉐이크 HEAVY→FINISH 정렬. ③ 힛스톱 매핑은 기존 유지. 데미지 넘버 재설계(④)와 파티클(⑤)은 Step 2/3 별도 진행 |
| 2026-04-19 | Pass 2 Step 2 (④ 데미지 넘버 재설계) — D7-4 사양 반영. `damage_number.gd` Galmuri11 LabelSettings + shadow offset 1px 아웃라인. 3티어: 일반=흰/12px, 크리티컬=노랑/14px + scale 1.4 오버슛, 피니시=속성색(클램프)/14px + 가로 쉐이크 0.24s. **크리티컬 소스 결정**: 보스 약점 히트 = 크리티컬로 간주 (일반 적엔 크리티컬 없음, 별도 확률 시스템 미도입). `base_boss._spawn_damage_number()`에 `is_critical`/`attribute` 파라미터 추가, `base_enemy._spawn_damage_number()`에 `attribute` 전파 |
| 2026-04-19 | Pass 2 Step 3 (⑤ 피격 파티클) — **Pass 2 완료**. `EffectsHitParticle` RefCounted 헬퍼 신규 (카테고리별 풀 2개×3=6 GPUParticles2D, round-robin restart, 4×4 흰색 fallback 텍스처). 3 카테고리: **organic**(tree/flower), **mineral**(rock/pillar/shard), **shadow**(dusk_spider/보스 기본). `data/effects/particle_presets.tres` + `EffectsParticlePresetsData` Resource로 외부화. `EffectsSystem.request_hit_particle(pos, category, is_finish, attr)` + `resolve_enemy_category(enemy_type)` API. 피니시 시 amount ×2.0·speed ×1.3 증폭 + 속성색 color_ramp swap. `base_enemy` / `base_boss._play_hit_feedback` 1줄씩 연결. 아트 명세 `docs/art_specs/hit_particles.md` 신규 + ART_RESOURCE_LIST #45~47 갱신(기존 비트맵 폰트 #47 폐기). Pass 3(시간 정지)으로 진입 가능 |
| 2026-04-19 | Pass 3 Step 1 (시간 정지 세피아 프레임워크) — `assets/shaders/effects/time_stop_sepia.gdshader` 신규 (SCREEN_TEXTURE 기반, `mix(original, sepia, weight)` 화면 전체 균일). **D7-1 재조정**: 원안 "주변부만 색상 유지"는 사용자 시각 검증 결과 "터널 시야"처럼 보여 몰입감 저하 → edge_mask 로직 완전 제거. `EffectsTimeStop` RefCounted 헬퍼 신규(`apply_instant(on)` + 셰이더 assign/param 설정, ~50줄). `EffectsConfigData`에 Time Stop 그룹 9개 필드 추가(sepia_tone / tint_color / saturation_lerp / weight_target / transition_duration / blue_pulse_color·duration / afterimage_count·interval·fade — Step 2~4 예약). 디버그 키 **F12** (F10/F11은 InventorySystem 선점, F5·F6·F7·F9는 GrowthSystem/기존 이펙트 — F12가 유일한 미점유). EventBus 구독·Tween·파티클·펄스·잔상은 Step 2~4 별도 진행. 신규 class_name `EffectsTimeStop` 등록 시 `--editor --headless --quit` 1회로 global_script_class_cache 갱신 필요. **검증**: gdlint 클린, 헤드리스 로드 클린 |
| 2026-04-19 | Pass 3 Step 2 (EventBus Tween 트랜지션) — `EffectsTimeStop`이 `EventBus.time_flow_stopped/started` 구독, 신규 `apply_transition(on)`으로 weight 0↔`time_stop_weight_target` Tween(`config.time_stop_transition_duration`=0.30s, `create_tween().set_ignore_time_scale(true).tween_method(...)`). `_weight_tween.kill()` 재진입 시 현재값→목표값으로 점프 없이 이어 감. `_current_weight` 로컬 추적(OverlaySystem getter 부재). `apply_instant`은 초기화 경로 유지(Tween도 kill). `EffectsSystem.debug_toggle_time_stop`은 `apply_transition` 호출로 전환되어 F12가 실제 트랜지션 미리보기로 동작(TimeSystem 상태는 건드리지 않음 — 적 정지/클럭 사이드이펙트 회피). **검증**: gdlint 클린(2개 파일), 헤드리스 로드 클린 |
| 2026-04-19 | Pass 3 Step 3 (freezable 그룹 + 플레이어 숨결) — `EffectsFreezable` RefCounted 헬퍼 신규(~35줄). `EventBus.time_flow_stopped/started` 구독 → `get_tree().call_group("freezable_particles", &"set", "speed_scale", 0.0/1.0)`. `apply(frozen: bool)` 수동 토글 노출(디버그/초기화용). `EffectsSystem._freezable` 멤버 + `_ready` 인스턴스화 + `debug_toggle_time_stop`이 셰이더 Tween·그룹 토글 동시 호출(TimeSystem 비오염). **Player.tscn**에 `BreathParticles` GPUParticles2D 신규: 위치 `(4,-28)`, amount=3 / lifetime=1.2s / explosiveness=0 / randomness=0.4 / speed_scale=1.0. process_material + GradientTexture2D(4×4 흰) + GradientTexture1D(alpha 0.85→0.45→0 페이드) 모두 scene sub_resource로 베이킹. **`freezable_particles` 그룹 비가입**(숨결은 정지 예외). 현재 그룹 멤버 0개 → Pass 5 앰비언트 파티클(꽃가루/반딧불) 합류 시 자동 편입. 설계 원칙: EffectsTimeStop은 셰이더 전담 / EffectsFreezable은 그룹 전담(단일 책임 분리). **검증**: gdlint 클린(2개 파일), `--editor --headless --quit` 캐시 갱신 후 `--headless --quit` 로드 클린 |
| 2026-04-20 | Pass 3 Step 4 (해제 블루 펄스 + 플레이어 잔상) — `EffectsAfterimage` 범용 RefCounted 헬퍼 신규(~95줄). `spawn(source: Node2D, count, interval, fade, tint)` — AnimatedSprite2D는 `sprite_frames.get_frame_texture(anim, frame)`로 현 프레임 추출, Sprite2D는 texture 직접. 복제본은 항상 Sprite2D.new() 단일 타입, `SceneTreeTimer(delay, process_always=true, ignore_time_scale=true)` 스케줄링, 페이드는 `ghost.create_tween().set_ignore_time_scale(true)` → queue_free. 부모는 `source.get_parent()`로 월드 좌표 고정(플레이어 이동해도 잔상 정지). `EffectsSystem.request_afterimage(source, count=-1, interval=-1, fade=-1)` API(기본값 -1이면 config `time_stop_afterimage_*` 사용). `EffectsTimeStop.apply_transition` 본문에 `if not on: _trigger_release_fx()` 훅 — EventBus·F12 경로 양쪽 자동 포함. `_trigger_release_fx`: `request_screen_flash(blue_pulse_color, blue_pulse_duration)` + `tree.get_first_node_in_group("player").get_node("AnimatedSprite2D")`로 잔상 트리거(Player 부재 시 graceful skip). `time_stop_blue_pulse_color` B채널 1.20→1.00 LDR 클램프(ColorRect 알파 페이드 기반이라 HDR 발광 안 함). **INARI 레퍼런스 분산**: HDR 블룸 베이스라인·코어/할로 2레이어·방사형 burst는 Pass 5로 이월(1구역 아트 확정 후, 피니시 컷인과 기법 공유). Step 4 = 최소안(펄스+잔상) 체감 검증 우선. Light Dash 연결은 범위 밖 — 헬퍼만 범용 API로 설계. **검증**: gdlint 클린(4개 파일), `--editor --headless --quit` 캐시 갱신 후 `--headless --quit` 로드 클린. F12 토글 체감 OK |
