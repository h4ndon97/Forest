# 컷신 일러스트 패널 — 아트 명세

> 관련: REC-FX-006 (정지 일러스트 + 텍스트박스 컷신)
> 코드: `src/ui/cutscene/cutscene_panel.gd` + `data/cutscenes/*.tres`

---

## 1. 용도

핵심 스토리 비트(보스 등장/처치, 봉인 회상, 가족 라인 분기 등)에 정적 일러스트로 인서트.
풀 애니 컷신 미사용. Blasphemous/Skul형 — **정지 일러스트 + 텍스트박스 + 음악 변화**.

---

## 2. 캔버스 규격

- **표준 사이즈**: **320×180 px** (게임 해상도 640×360의 정확히 1/2)
- **표시 방식**: `TextureRect.STRETCH_KEEP_ASPECT_CENTERED` + `TEXTURE_FILTER_NEAREST`
- **위치**: 화면 중앙 상단(텍스트박스 위 공간 중앙)
- **여백**: 일러스트 가장자리에서 1~2px 안전 여백 (UI 페이드 시 자르지 않도록)
- **포맷**: PNG (RGBA, 투명 배경 허용)

> 더 정밀한 일러스트가 필요하면 480×270 또는 640×360까지 허용. KEEP_ASPECT_CENTERED가 자동 축소.

---

## 3. 톤/팔레트

- **차별화 톤**: 인게임 픽셀아트와 **다른 톤** (수묵화 풍 / 단색 음영 / 한정 팔레트)
  - 근거: REC-MKT-002 (수묵화 톤) + Blasphemous 컷이 일반 게임 화면과 시각적으로 명확히 분리됨
- **팔레트 권장**: 4~6색 한정. 보라/검정/황혼 황색을 기본 축으로 시조 풍 회상 톤
- **테마별 변주**:
  - 회상/봉인 의식 → 차가운 푸르스름
  - 보스 등장(그림자 왕가) → 보라/검정 + 적색 핀
  - 보스 등장(빛 왕가) → 황혼 황색 + 흰색 코어
  - 진실 노출/엔딩 분기 → 단색 + 강한 명암 대비

---

## 4. 구도 가이드

- **단일 피사체** 중심 (인물 1명 / 왕좌 1개 / 봉인석 1개 등)
- 인물 컷의 경우 **흉상 또는 전신 실루엣** — 표정 디테일은 픽셀 한계로 약화, 자세/실루엣으로 감정 전달
- 화면 가장자리에 **추상 요소** (이끼·뿌리·결정 등) 배치 가능 → 분위기 보강

---

## 5. 페이드/타이밍 통합

코드(cutscene_panel.gd)가 자동 처리:
- 일러스트 등장: `CutscenePanelData.fade_in` (기본 0.6s)
- 일러스트 퇴장: `CutscenePanelData.fade_out` (기본 0.6s)
- 텍스트 typewriter: 32 cps (코드 상수)
- 페이드 중에도 시네마틱 바는 그대로 유지 → 일러스트만 교체되는 효과

---

## 6. 발광 3레이어 규약 적용 여부

> 본 프로젝트 메모리 [feedback_art_spec_three_layer_default] — 캐릭터/적/보스/광원 명세는 3레이어 규약 §6.7 자동 포함.

### 6.1 적용 대상 — **광원 또는 발광체가 일러스트에 등장하는 경우**
컷신 일러스트가 정적이라 게임 내 발광 셰이더는 적용되지 않음. 그러나 **회상/봉인 의식/시간 코어/보스 광원** 등이 그려진다면 3레이어 분리 export 권장:
- `cutscene_xxx_base.png` — 기본 색면/실루엣
- `cutscene_xxx_core.png` — 광원 내부 밝기 (additive blend 권장)
- `cutscene_xxx_halo.png` — 광원 외곽 페이드 (alpha blend, soft glow)

코드는 향후 `CutscenePanelData`에 `core_path/halo_path` 추가 시 3개 TextureRect 컴포지트 가능. 현재는 단일 `image_path`만 — 첫 컷신 작업 시 결정.

### 6.2 적용 대상 외 — 정적 풍경/봉인석/인물 흉상
1레이어로 충분. 발광 요소가 그림 자체에 합쳐져 있는 평면 일러스트.

### 6.3 권장 출발점
첫 5장은 **1레이어 단일 PNG**로 시작 → 효과 부족 시 핵심 1~2장만 3레이어로 재제작.

---

## 7. placeholder 동작

일러스트 미존재 또는 로드 실패 시 코드 자동 fallback:
- `CutscenePanelData.placeholder_tint` 색의 320×180 ColorRect 표시
- 텍스트박스/화자 라벨은 정상 작동
- 작가 협업 정책 [feedback_art_ready_code] 부합 — 코드 수정 없이 일러스트만 넣으면 즉시 반영

---

## 8. 1차 우선순위 컷신 5장 (REC-FX-006 본문 발췌)

| # | 트리거 | 톤 | 등장 요소 | 비고 |
|---|---|---|---|---|
| 1 | 게임 시작 | 차가운 푸르스름 | 봉인 의식 / 시조 인물 군상 | 회상 |
| 2 | 1보스 처치 | 황혼 황색 | 첫 봉인 균열 | 단순 |
| 3 | 3보스 처치 | 보라/검정 | 그림자 왕가 정체 | 인물 흉상 |
| 4 | 4보스 처치 | 단색 강대비 | 선조 거래 진실 | 진실 노출 |
| 5 | 최종 보스 직전 | 흑·백 결합 | 두 왕가 결합 직전 | 절정 |

> 본 프로젝트 zone3 진입 시점(2026-04-26)에서는 ThroneEcho 등장용 placeholder 컷신(`throne_echo_intro.tres`) 1건만 시연용으로 추가됨. 위 5장은 작가 일정에 맞춰 별도 작업.

---

## 9. 파일 배치

```
assets/sprites/cutscenes/
├── cutscene_intro_seal.png        # 일러스트 1장당 PNG 1~3개
├── cutscene_intro_seal_core.png   # (3레이어 적용 시)
├── cutscene_intro_seal_halo.png
├── cutscene_boss1_crack.png
└── ...

data/cutscenes/
├── cutscene_data.gd               # Resource 스크립트 (정의됨)
├── cutscene_panel_data.gd
├── throne_echo_intro.tres         # placeholder 시연
├── intro_seal.tres
└── ...
```
