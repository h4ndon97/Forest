# 시간이 멈춘 숲 — 플레이어 아트 명세서

> 주인공 **헬린(Helin)** 스프라이트 명세. 현재 프로젝트에는 구 규격(64×64) `player_spritesheet.png`이 임시로 들어가 있으며, 본 문서의 신규 규격(128×128)으로 교체하는 것이 목표다.
>
> **관련 문서**:
> - [CHARACTER.md](../CHARACTER.md) — **캐릭터 컨셉 마스터** (정체성/외형/등불/빛무기/팔레트 5단계 결정)
> - [ART_PIPELINE.md](../ART_PIPELINE.md) — 프로젝트 전역 아트 규격
> - [ART_RESOURCE_LIST.md](ART_RESOURCE_LIST.md) Phase 1 리메이크 / Phase 1-1 / Phase 1-4 — 원본 리스트
> - [STORY.md](../STORY.md) §3 주인공 — 서사적 정체성
> - [COMBAT.md](../COMBAT.md) — 콤보 / 대시 모션 의도

---

## 1. 캔버스 / 크기 규격

| 항목 | 값 | 비고 |
|---|---|---|
| **캔버스 크기** | **128×128** | 프레임당. 모든 애니메이션 공통 |
| **실효 캐릭터** | 약 64×64 | 캔버스 중앙 정렬. 나머지는 모션/이펙트 여백 |
| **콜리전 박스** | 14×28 | [Player.tscn](../../src/entities/player/Player.tscn)의 현재 값. 아트 교체 시 유지 |
| **스프라이트 offset** | `Vector2(0, -16)` | 발끝이 콜리전 하단에 맞도록 위로 올림 |
| **타일 대비** | 약 1타일(64×64) | 세계의 타일 기준과 동일. 캔버스는 여백 포함 |
| **앵커** | 하단 중앙 | 발끝이 바닥 기준 |
| **픽셀 필터** | Nearest (프로젝트 전역 설정) | 보간/안티에일리어싱 금지 |

### 128×128로 확장하는 이유
- 기존 64×64는 세부 표현에 제약이 컸음 (등불, 머리카락, 의상 디테일)
- 확장된 여백 안에서 **베기 궤적**, **대시 애프터이미지**, **등불 흔들림**이 스프라이트 내에서 자연스럽게 표현 가능
- 실제 캐릭터 크기는 64×64 유지 → 충돌 박스/레벨 디자인은 그대로

### 크기 비교 참고

```
  꽃 적 (64×64)  <  플레이어 (128×128 캔버스 / 실효 64×64)  <  나무 적 (128×128)  <  땅거미 (192×192)
```

---

## 2. 캐릭터 디자인 컨셉

> **본 섹션은 [CHARACTER.md](../CHARACTER.md)의 요약**. 디자인 결정의 출처·이유·후속 변화 여지는 CHARACTER.md를 참조.

### 정체성

- **이름**: 헬린 (Helin) — 18~22세 청년기
- **성격**: 차분함 / 사명감 / 내면의 의심
- **서사**: 제사장 가문의 후예. 선조의 능력(시간 조작 + 등불)을 물려받음. 후반 진실 발견 후 흔들리는 인물

### 비례

**3.5등신 chibi 톤** — Death's Door / Eastward / Sea of Stars 류. 캔버스 128×128, 실효 캐릭터 ~64×64.

### 외형 실루엣

| 부위 | 결정 |
|---|---|
| **상체 톤** | 사제 (후드 + 로브 + 황금 데코) |
| **하체 톤** | 기동성 (타이트 레깅스 + 단화) |
| **후드** | 반쯤 걸침 (이마~눈 위만 그림자) |
| **로브** | 짧은 깔끔 (허벅지 위~무릎 위) |
| **머리** | 어깨선 길이 (묶음 디테일은 시안 단계 가변) |
| **옷차림** | 부분적으로 닳은 사제복 + 가장자리·문양 단위 황금 데코 |

### 등불 (왼손, 고정)

- **형태**: 고전 랜턴 (육각 케이지 + 손잡이 + 위쪽 캡). 톤 매칭 = 현재 저장소 [hud_consumable_hp.png](../../assets/ui/hud/hud_consumable_hp.png)
- **빛 색**: 따뜻한 황금 외곽 + 옅은 시안 코어
- **심지**: 작은 빛 결정 (1~2px 시안 점)
- **매체 (서사)**: 그림자 왕가의 봉인된 권능 조각 — 후반 진실 발견 시 색 변화 여지
- **3레이어**: base (메탈 케이지) / core (황금 + 시안) / halo (발광) — 광원 대상 3레이어 규약 적용
- **PointLight2D**: 별도 자식 노드. 등불 머리 부분 픽셀 위치를 가급적 일정하게 유지

### 빛무기 (오른손, 공격 순간만 응결)

- **형태**: 한손 세이버 / 커틀러스 (50~60px, 살짝 휜 형태)
- **빛 질감**: 결정형 (단단한 코어 + 외곽 1~2px 산란)
- **평상시 색**: 황금 단일 (등불과 통일)
- **피니시 색**: `EffectsSystem.get_finish_color` 코드 분기 — light 흰 강조 / shadow 보라 / hybrid 시안
- **모션 룰**: idle/run/jump/fall은 **빈 오른손 또는 작은 빛 점만**, slash_1~4는 **검 응결**한 상태. 작업량 절감 + "등불에서 빛 응축 → 검 형성" 컨셉 정합

### 연출 의도

- idle 상태에서도 **숨쉬기 + 등불 흔들림**이 보이는 정적이지 않은 모션
- 피격 시 한 손 방어 자세 — 등불을 감싸는 듯한 인상
- 죽음 시 등불이 바닥에 떨어져 흔들리는 연출 (서사적 중요 순간)
- 컷신에서 후드를 들어올리는 연출 — REC-FX-006 정지 일러스트 컷신 인프라와 시너지

---

## 3. 애니메이션 목록

> 모든 프레임은 **128×128 캔버스, 가로 스트립(Horizontal Strip)** 으로 내보낸다.
> 태그별로 별도 PNG 파일 권장 (Aseprite `--split-tags` 사용).

### 3.1 Phase 1 리메이크 — 기본 상태

| 파일명 | 프레임 수 | 루프 | 설명 |
|---|---|---|---|
| `player_idle.png` | 4 | ✅ | 숨쉬기 + 등불 흔들림. 속도 10 fps 기준 |
| `player_run.png` | 6 | ✅ | 등불 손에 든 자세로 달리기. 속도 10 fps 기준 |
| `player_hurt.png` | 3 | ❌ | 피격 리액션. 뒤로 밀림 + 한 손 방어 자세 |
| `player_death.png` | 6 | ❌ | 쓰러짐. 등불 바닥에 떨어져 흔들림 |
| `player_interact.png` | 4 | ❌ | 환경 오브젝트 조작 / 아이템 줍기 공통 |

**우선순위**: hurt / death (피격 피드백 필수) > idle / run (리메이크) > interact

### 3.2 Phase 1-1 — 이동 확장

| 파일명 | 프레임 수 | 루프 | 설명 |
|---|---|---|---|
| `player_jump.png` | 2~4 | ❌ | 점프 시작/상승 |
| `player_fall.png` | 2~4 | ❌ | 낙하 |
| `player_dash.png` | 2~3 | ❌ | 대시. 애프터이미지는 코드 측에서 처리하되 모션 자체에 "쏠림" 포함 가능 |

### 3.3 Phase 1-4 — 콤보 공격 (오른손 무기)

| 파일명 | 프레임 수 | 루프 | 설명 |
|---|---|---|---|
| `player_slash_1.png` | 3~4 | ❌ | 가벼운 횡베기 (1타) |
| `player_slash_2.png` | 3~4 | ❌ | 반대 방향 횡베기 (2타) |
| `player_slash_3.png` | 3~4 | ❌ | 더 강한 횡베기 (3타) |
| `player_slash_4.png` | 4~6 | ❌ | 가장 강한 마무리 공격. 이펙트 포함 가능 (4타 피니시) |

> 콤보 중에도 **왼손 등불은 안정적으로 유지**되어야 한다. 흔들림은 있어도 위치 이탈 X.

### 3.4 향후 확장 (Phase 2 이후, 본 문서에선 규격만 예고)
- `player_magic.png` — 스킬 시전 모션 (SKILLS.md 진행 시 확정)
- 대시 애프터이미지·베기 궤적은 **별도 이펙트 레이어**로 분리될 수도 있음 (Phase 3-7 이펙트 패스에서 결정)

#### 강화 이동 후속 공격 (Phase 4-0 #4 Step 5 — 잠정 미제작, slash_4 fallback 재사용)

현재 follow-up 4종은 `slash_4` 애니메이션을 재사용한다. 전용 모션이 추가되면 자동 활성화 — `player_animation.gd`의 `DYNAMIC_ANIM_PATHS`에 다음 파일명 등록만 하면 됨(코드 수정 불필요).

| 파일명 | 발동 | 설명 |
|---|---|---|
| `player_follow_up_light_dash.png` | LIGHT_DASH 종료 후 0.05s 자동 | 빛 잔상 끝의 짧은 정면 베기 (관통 강조) |
| `player_follow_up_shadow_step.png` | SHADOW_STEP 후 0.25s attack | 적 등 뒤에서 2단 다단 베기 |
| `player_follow_up_light_leap.png` | LIGHT_LEAP 후 0.25s attack | 공중 burst 끝의 낙하 베기 |
| `player_follow_up_shadow_phase.png` | SHADOW_PHASE 후 0.25s attack | 잠수 해제 직후 강화 기습 |

- 프레임 수: 3~5 권장 (slash_4와 비슷한 임팩트). 128×128.
- 시각 단서(screen flash + afterimage burst)는 코드 측에서 발동 — 스프라이트 자체는 베기 동작에 집중.

---

## 4. 출력 규칙

### 4.1 폴더 / 네이밍
- **경로**: `assets/sprites/player/`
- **파일명**: snake_case, `player_<state>.png` 형식 ([CLAUDE.md](../../CLAUDE.md) §2.5 준수)
- **JSON 데이터** (선택): `player_<state>.json` — Aseprite가 태그 정보 포함해 내보냄

### 4.2 Aseprite 내보내기 설정

```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → Canvas: 128×128
  → Tag별 별도 내보내기 (--split-tags 또는 태그별 Export 반복)
  → Output: assets/sprites/player/player_<tag>.png
  → Data: JSON (Hash) 포함 권장 (Godot에서 프레임 슬라이싱 참고용)
```

CLI 예시:
```bash
aseprite --batch player.ase \
  --split-tags \
  --sheet assets/sprites/player/player_{tag}.png \
  --data  assets/sprites/player/player_{tag}.json
```

### 4.3 기존 에셋 처리
- **기존 `player_spritesheet.png` (64×64)** 는 삭제하지 말고 **fallback으로 유지**
- [player_animation.gd](../../src/entities/player/player_animation.gd)의 `DYNAMIC_ANIM_PATHS`에 등록된 파일명(`player_idle.png` / `player_run.png` / `player_slash.png` / `player_slash_1~4.png` / `player_jump.png` / `player_fall.png` / `player_dash.png` / `player_light_dash.png`)이 `assets/sprites/player/`에 존재하면 **자동으로 기존 애니메이션을 덮어쓴다**. Player.tscn의 AtlasTexture 수정 불필요
- 프레임 크기는 텍스처 height에서 자동 감지(가로 스트립 전제). 64×64 / 128×128 혼용 가능 — 개별 파일 단위로 증분 교체

---

## 5. 제작 순서 권장

**이 순서로 제작하면 기능이 즉시 복원됨** (우선순위 = 현재 fallback 동작 → 완성도 향상):

1. **idle + run** (128×128) — 게임의 대부분 시간 동안 보이는 상태
2. **slash_1 ~ slash_4** — 전투의 핵심. 특히 4타 피니시는 타격감 직결
3. **hurt + death** — 피격 피드백. 현재 비어 있어 체감상 가장 큰 공백
4. **jump + fall + dash** — 이동의 질감 완성
5. **interact** — 환경 조작. 가장 후순위

각 단계마다 한 파일씩 넣어도 `player.gd` 쪽이 fallback 유지하도록 설계되어 있으므로 **증분 교체 가능**.

---

## 6. 색상 / 팔레트 (사용자 자율 결정)

> **결정 방식 (2026-05-02 확정)**: 사용자가 픽셀아트를 직접 제작하시므로 정확한 hex 값은 사용자 자율. 시안 완성 시 [CHARACTER.md §6.2](../CHARACTER.md) 잠정 참고값을 실제 사용 색으로 갱신.

### 6.1 유지해야 할 4가지 관계 (필수)

1. **등불이 화면에서 가장 밝은 점** — 의상 황금 데코의 채도·명도 < 등불 황금
2. **얼굴 영역 식별 가능** — 후드 그림자 안에서도 피부·눈·머리 라인 식별
3. **명도 V자 구조 (권장)** — 후드(어둠) → 얼굴/등불(밝음) → 하의(어둠)
4. **속성 피니시 색은 코드 담당** — 평상시 의상·검 색은 자유, 피니시 시 코드가 동적 분기

### 6.2 잠정 참고값 (강제 아님)

[CHARACTER.md §6.2](../CHARACTER.md) 표 참조. 시안 작업 시 위 4가지 관계 점검만 필수.

### 6.3 팔레트 방향 메타

현재 프로젝트의 팔레트 방향(빛/그림자 이중 축)은 [ui_design_master.md](ui_design_master.md)에 정리되어 있다. 플레이어 스프라이트는 **플레이어 HUD 축(빛/그림자)** 에 맞춰 제작되되, 숲 세계관과 완전히 분리되지는 않아야 한다.

---

## 7. 체크리스트 (아트 작업 시 확인용)

- [ ] 캔버스 128×128 고정
- [ ] 실효 캐릭터 ~64×64, 발끝이 캔버스 하단 안전 영역에 위치
- [ ] 왼손에 등불 포함, 애니메이션 내내 위치 일관
- [ ] 픽셀 아트 Nearest — 안티에일리어싱 금지
- [ ] 가로 스트립(Horizontal Strip) 레이아웃
- [ ] 파일명 `player_<state>.png` (snake_case)
- [ ] `assets/sprites/player/` 경로 배치
- [ ] Aseprite 태그로 애니메이션 구분 (단일 `.ase`로 관리 + `--split-tags` 내보내기 권장)
- [ ] 프레임 간 등불 빛 위치는 `PointLight2D`가 따라붙을 것을 염두에 두고 **등불 머리 부분의 픽셀 위치를 가급적 일정하게** 유지
