# 시간이 멈춘 숲 — 아트 파이프라인

> 이 문서는 픽셀아트 제작 도구, 해상도, 에셋 구조, Godot 반영 방식을 정의한다.
> 모든 아트는 1인 개발자가 직접 제작한다.

---

## 1. 제작 도구 (확정)

- **Aseprite** — 모든 아트 요소 (캐릭터, 적, UI, 맵, 타일, 배경, 이펙트)
- 애니메이션: Aseprite 태그 기반으로 상태별 구분 (Idle, Run, Slash 등)
- 내보내기: 스프라이트 시트 (PNG)

### 미결 사항
- [ ] 타일맵 제작 방식 (Aseprite → Godot TileMap? 별도 툴?)

---

## 2. 해상도 / 스케일

### 기본 규격 (확정)
- **타일 크기**: 64×64
- **캐릭터 캔버스**: 128×128 (모션/이펙트 자유도를 위해 여백 포함)
- **캐릭터 실제 크기**: 64×64 기준, 캔버스 내에서 작업

### 게임 해상도 (확정)
- **기본 해상도**: 640×360
- **스케일링**: 정수배 3배 → 1920×1080 (1080p)
- 화면에 약 10×5.6 타일 표시

### 미결 사항
- [ ] 적/보스 캔버스 크기 (유형별 다를 수 있음)

---

## 3. 에셋 구조

### 미결 사항
- [ ] 폴더 구조 (캐릭터, 적, 타일, 배경, UI, 이펙트 등)
- [ ] 네이밍 컨벤션
- [ ] 스프라이트 시트 vs 개별 프레임 (스프라이트 시트 유력)

---

## 4. Godot 반영 방식

### 확정
- 텍스처 필터링: **Nearest** (픽셀아트 필수)
- Aseprite 태그 → Godot 애니메이션 이름으로 매핑

### 미결 사항
- [ ] 애니메이션 시스템 (AnimatedSprite2D? AnimationPlayer?)
- [ ] Aseprite → Godot 임포트 플러그인 사용 여부
- [ ] 타일맵 시스템 설정

---

## 5. 아트 명세서

### 워크플로우 (확정)
- **개발자(AI)**: Godot 구현 + 아트 명세서 작성
- **아티스트(사용자)**: 명세서를 보고 Aseprite로 리소스 제작

### 명세서 포함 항목
| 항목 | 내용 |
|---|---|
| 캔버스 크기 | 가로×세로 픽셀 |
| 애니메이션 목록 | 태그명 및 설명 |
| 프레임 수 | 애니메이션별 프레임 수 |
| 프레임 속도 | FPS 또는 ms/프레임 |
| 내보내기 형식 | 스프라이트 시트 PNG |
| 네이밍 규칙 | 파일명 컨벤션 |
| **발광 레이어 구성** | **§6.7 발광 3레이어 규약 적용 여부. 적용 시 base/core/halo 각 레이어의 제작 가이드 포함** |
| **속성 매핑** | **발광 대상인 경우 `core`/`halo`에 사용할 속성색 (light=흰 / shadow=보라 / hybrid=금)** |

> **캐릭터/적/보스/광원 오브젝트의 아트 명세서는 반드시 §6.7 발광 레이어 구성 섹션을 포함**한다. 템플릿: [art_specs/_character_spec_template.md](art_specs/_character_spec_template.md)

### 미결 사항
- [ ] 명세서 작성 시점 (프로토타입 이후 본격 작성)

---

## 6. 이펙트 아트 규격

> 설계 전문: `docs/EFFECTS.md` 참조. 본 섹션은 제작 규격만 정리.

### 6.1 파티클 텍스처
- **크기**: 4×4 ~ 8×8 (작은 입자), 16×16 (중간), 32×32 (큰 파편)
- **개수**: 한 종류당 3~5종 변형 (랜덤 선택용)
- **저장**: `assets/sprites/effects/particle_*.png`
- **색상**: 단색 흰색 기본 → 코드에서 modulate로 색상 변경
- **투명도**: 알파 채널 유지 (PNG)

### 6.2 오버레이 (화면 전체)
- **크기**: 640×360 (게임 기본 해상도, 스케일링은 CanvasLayer 측 처리)
- **저장**: `assets/ui/overlay_*.png` 또는 `assets/ui/vignette_*.png`
- **형태**: 원형 그라데이션(비네트), 4변 그라데이션(경계 경고), 노이즈(디졸브)
- **적용**: CanvasLayer 최상단 TextureRect, blend_mode 옵션 (Multiply/Additive)

### 6.3 슬래시/트레일 스프라이트
- **캔버스**: 64×32 (기본) / 128×64 (피니시)
- **프레임**: 4~8 가로 스트립
- **저장**: `assets/sprites/effects/slash_*.png`
- **컨벤션**: 오른쪽 방향 기준 제작, 좌향은 코드 flip_h
- **투명도**: 가장자리 페이드 포함

### 6.4 HUD 이펙트 에셋
- **크랙 오버레이**: 640×360, 알파 채널로 빈사 상태 표현
- **디졸브 노이즈**: 256×256, 타일링 가능한 그레이스케일
- **데미지 폰트 (선택)**: BitmapFont 또는 Pixel Font (.fnt)
- **저장**: `assets/ui/hud_*.png` 또는 `assets/ui/overlay_*.png`

### 6.5 애니메이션 FPS 가이드
| 용도 | 권장 FPS |
|---|---|
| 슬래시/공격 이펙트 | 20~24 (짧고 빠름) |
| 파티클(코드 제어) | 프레임 단위 아님 (GPUParticles2D lifetime로 제어) |
| 오버레이 페이드 | Tween (프레임 아님) |
| UI 팝업 | Tween + 0.3~0.6s |

### 6.6 이펙트 파일 폴더 구조
```
assets/sprites/effects/      # 인게임 이펙트 스프라이트
  slash_*.png                # 검광/베기
  particle_*.png             # 파티클 텍스처
  fx_*.png                   # 기타 이펙트 (기존)

assets/ui/                   # UI/HUD 이펙트
  vignette_*.png             # 비네트 오버레이
  overlay_*.png              # 일반 오버레이
  hud_*.png                  # HUD 전용 요소 (크랙 등)
```

---

### 6.7 발광 스프라이트 3레이어 제작 규약 (2026-04-22 잠정 확정)

> **배경**: INARI 수준의 발광 이펙트는 블룸 활성화만으론 나오지 않는다. 스프라이트 자체가 **코어(순백) + 할로(고채도)**로 분리 제작되어야 HDR 블룸이 이를 "뜨겁게" 만든다. 자세한 맥락: [art_specs/effects_pass3_step4_inari_ref.md](art_specs/effects_pass3_step4_inari_ref.md) §3 블룸의 성격 / §1.5 Pass 5 진입 블로커.
>
> **잠정 확정**: 아트 작업 중 재조정 가능 (UI 설계 결정 가변성 원칙). 단 본격 제작 전 합의된 원칙으로 취급한다.

#### 6.7.1 적용 대상

**3레이어 필수**:
- 플레이어, 적(일반/엘리트), 보스
- 광원 오브젝트 (횃불, 등불, 수정, 거울, 반사 바닥, 포탈)

**단일 레이어 유지** (불필요 — 이펙트 자체가 발광):
- 공격 이펙트 스프라이트 (슬래시 트레일, 스킬 이펙트)
- 환경 타일 (나무, 바위, 지면)
- UI (HUD pip 포함 — HDR 발광 아님)
- 파티클 텍스처

#### 6.7.2 Aseprite 레이어 구조

```
sprite_name.aseprite
├── halo     (고채도 외곽 발광, 블룸이 확산하는 주체)
├── core     (순백 또는 속성색 코어, 피니시/크리티컬 시만 보임)
└── base     (평상 스프라이트, 항상 보임)
```

**레이어 역할**:
| 레이어 | 색상 | 표시 조건 | 제작 가이드 |
|---|---|---|---|
| `base` | 스프라이트 원래 팔레트 | **항상 표시** | 평상시 보이는 캐릭터. 기존 제작 방식 그대로 |
| `core` | 순백(`#FFFFFF`) 또는 속성색 | 피니시/크리티컬/강조 이벤트 시만 | `base`의 내부 1~2px 두께, "발광의 중심" |
| `halo` | 고채도 속성색 HDR 후보 | 피니시/크리티컬/강조 이벤트 시만 | `base` 외곽 1~2px 바깥, 반투명/블러 느낌 |

**속성색 매핑** (이미 확정된 D7-2 디렉션):
- `light` = `#FFFFFF` 순백 HDR
- `shadow` = `#8B2FC6` 보라 HDR
- `hybrid` = `#F2CC66` 금 HDR

#### 6.7.3 Aseprite Export

레이어별 PNG 분리:
```bash
aseprite --batch input.ase --layer "base"  --sheet base.png
aseprite --batch input.ase --layer "core"  --sheet core.png
aseprite --batch input.ase --layer "halo"  --sheet halo.png
```

**파일 명명**:
```
assets/sprites/player/
  player_base.png
  player_core.png     (피니시 대상이므로 생성)
  player_halo.png
  player_spritesheet.json   (프레임 정보 — 3레이어 공통)
```

**JSON 메타데이터**: base 기준 1회만 생성. core/halo는 동일 프레임 레이아웃을 공유하므로 중복 불필요.

#### 6.7.4 Godot 구조

```
Player (CharacterBody2D)
└── Visual (Node2D)
    ├── Base (AnimatedSprite2D, z=0, visible=true)
    ├── Core (AnimatedSprite2D, z=1, visible=false, blend=normal)
    └── Halo (AnimatedSprite2D, z=2, visible=false, blend=add)
```

**3개 AnimatedSprite2D 모두 같은 animation 이름 공유** (`idle`, `run`, `hurt` 등). 세 레이어가 동기화되어 재생되도록 Core/Halo의 `frame_changed`는 Base 따라감(또는 동일 SpriteFrames 에셋을 셰어).

**피니시/크리티컬 시**:
```gdscript
# 2레이어 활성화 + 속성색 modulate + Tween 페이드
core.visible = true
halo.visible = true
core.modulate = EffectsSystem.get_finish_color(attr)
halo.modulate = EffectsSystem.get_finish_color(attr)
# ...Tween으로 alpha 1→0 페이드 (지속 시간 Pass 5 값 튜닝)
```

실제 구현 API는 Pass 5에서 `EffectsSystem.request_finish_glow(target_visual, attribute)` 형태로 추상화 예정.

#### 6.7.5 Phase별 도입 계획

| Phase | 적용 대상 | 비고 |
|---|---|---|
| **Phase 3-7 ~ 4-0 (현재)** | **새로 제작하는 적/보스/광원**부터 3레이어 | 기존 플레이어/꽃 적은 유지 |
| **Phase 3-7 1구역 본격 아트 리비전** | 플레이어 재작업 시 3레이어로 합류 | 재작업 타이밍에 맞춰 |
| **Pass 5 (이펙트 본진)** | Core/Halo 활성화 로직 코드 구현 | HDR 블룸 베이스라인(E1-5) 선행 필요 |

#### 6.7.6 검증 체크리스트

신규 발광 대상 스프라이트 제작 시:
- [ ] Aseprite 파일에 `base` / `core` / `halo` 세 레이어 존재
- [ ] `core`는 `base`의 내부 1~2px 두께
- [ ] `halo`는 `base` 외곽 1~2px 바깥
- [ ] 세 레이어 모두 동일 애니메이션 태그 (tag명 통일)
- [ ] Export 시 3개 PNG 분리 (`*_base.png` / `*_core.png` / `*_halo.png`)
- [ ] `core`/`halo`에 순백/속성색 기본값만 사용 (세부 음영 금지 — 셰이더가 처리)

### 미결 사항
- [ ] 이펙트 팔레트 정의 (힛 플래시/파티클 색상 체계)
- [ ] 비트맵 폰트 사용 여부 (데미지 넘버)
- [ ] `core`/`halo` 프레임별 위치가 `base`와 정확히 일치하지 않을 때의 조정 방법 (Aseprite 레이어 동기화 규약)
