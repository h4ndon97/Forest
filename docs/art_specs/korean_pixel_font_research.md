# 한글 픽셀 폰트 조사 — 시간이 멈춘 숲

> **목적**: 상용 출시(Steam) 예정 2D 픽셀아트 메트로배니아의 본문/UI 폰트 결정.
> **결정 축**: 직접 제작 vs 무료 라이선스 vs 유료 라이선스.
> **타겟 크기**: 12px / 16px (640x360 기준 본문은 12px, 강조/제목은 16px 권장).
> **작성일**: 2026-04-18

---

## 1. 핵심 요약 (TL;DR)

- **상용 라이선스 안전 + 게임에 가장 적합**: **Galmuri**, **Neo둥근모**, **Mulmaru** 셋이 사실상 표준. 모두 OFL 1.1.
- **유료 옵션**: Yoon Design의 `Yoon px` 시리즈가 11,172자 풀 한글 + 모던 정돈된 디자인. 단, **Adobe Fonts 경유는 게임 임베딩 금지** — 직접 라이선스 구매 협상 필요.
- **직접 제작**: 2,350자 KS X 1001 기준 **약 200~400시간**. 시각적 차별화 가치는 크지만, 본 프로젝트의 1인 개발 + 1~2년 출시 일정에선 **비추천**.
- **추천**: **Galmuri11(본문) + Galmuri14(제목/HUD) 채택 + 로고/타이틀만 직접 제작 픽셀 레터링**. 라이선스 무료, 게임에 최적화된 디자인, 즉시 적용 가능.

---

## 2. 무료 한글 픽셀 폰트 후보

### 2.1 비교표

| 폰트 | 디자이너 | 사이즈 (px) | 한글 커버리지 | 라이선스 | 상용 OK | 추천도 |
|---|---|---|---|---|---|---|
| **Galmuri11** | Quiple (이민서) | 12px (9pt) | 11,172자 (전체) ※ | OFL 1.1 | OK | ★★★★★ |
| **Galmuri14** | Quiple | 15px (11pt) | 11,172자 ※ | OFL 1.1 | OK | ★★★★★ |
| **Galmuri9** | Quiple | 10px (7.5pt) | 11,172자 ※ | OFL 1.1 | OK | ★★★★ |
| **Galmuri7** | Quiple | 8px (6pt) | 4,358자 (Adobe-KR-0/1) | OFL 1.1 | OK | ★★★ |
| **Neo둥근모** | 정은빈 (Dalgona) | 16px 기반 (DOS 둥근모꼴 원본) | 11,172자 | OFL 1.1 | OK | ★★★★ |
| **Neo둥근모 Code** | 정은빈 | 16px | 11,172자 | OFL 1.1 | OK | 코드용 |
| **Neo둥근모 Pro** | 정은빈 | 8x16 / 16x16 비례폭 | 11,172자 | OFL 1.1 | OK | ★★★★ |
| **Mulmaru** (물마루) | mushsooni | 12px (9pt) | 11,172자 + 51 호환 | OFL 1.1 | OK | ★★★★ |
| **Mulmaru Mono** | mushsooni | 12px | 11,172자 | OFL 1.1 | OK | ★★★ |
| **DOSSaemmul** (도스샘물) | leedheo | 16x16 BDF + TTF | 한글 + CJK 광범위 | MIT | OK (귀속) | ★★ |

> ※ Galmuri 11/14: 핵심 자주 쓰는 2,355자는 디자이너가 직접 디자인, 4,358자(Adobe-KR-0+1)는 검수 완료, 나머지는 자동 생성. 결과적으로 **모든 11,172자 글리프 자체는 폰트 안에 존재**.

### 2.2 폰트별 상세

#### Galmuri (갈무리) — **최우선 추천**
- **디자이너**: Quiple (Minseo Lee, 이민서)
- **콘셉트**: 닌텐도 DS 폰트 디자인에서 영감. 게임용으로 가장 잘 다듬어진 한글 픽셀 폰트.
- **변형판**: Galmuri7 / 9 / 11 / 11 Bold / 11 Condensed / 14 (총 6종)
- **한글 커버리지**:
  - Galmuri 14/11/9: 핵심 2,355자 + Adobe-KR-0/1 4,358자 검수, 11,172자 전체 글리프 포함.
  - Galmuri7: 8px이라 4,358자만 정식 지원.
- **라이선스**: SIL Open Font License 1.1 — **상용 게임 임베딩 OK**.
- **다운로드**: https://github.com/quiple/galmuri (Releases) / https://quiple.dev/font/galmuri / Noonnu (https://noonnu.cc).
- **사용 사례**: Stardew Valley 한글 모드, 다수의 한국 인디 게임/팬 번역에서 사실상 표준.
- **Godot 4.x 렌더링 노트**:
  - Antialiasing: **Disabled**
  - Hinting: **None**
  - Subpixel positioning: **Disabled**
  - Generate Mipmaps: **Off**
  - **반드시 픽셀 사이즈의 정수배(12, 24, 36...)로만 사용**. 비정수배는 흐려짐.
- **문서/제목 표기 가이드**: 저작자가 폰트 자체에 대해 "비트맵 폰트는 미국·한국에서 저작권 대상이 아니다"라고 명시. 단 OFL 준수 필요.

#### Neo둥근모 (Neodgm) — **레트로 분위기 시 우선**
- **디자이너**: 정은빈 (Dalgona) — 1990년대 IT문화원 김중태 director의 DOS 비트맵 "둥근모꼴" 기반.
- **콘셉트**: DOS 시절 둥근모꼴의 향수 + 모던 TrueType. 직각 둥근맛.
- **변형판**:
  - Neo둥근모 (표준 16px 모노)
  - Neo둥근모 Code (코드 가독성용 변형)
  - Neo둥근모 Pro (8x16 / 16x16 비례폭, 별도 저장소)
- **한글 커버리지**: 11,172자 전체 (현대 한글 완성형).
- **라이선스**: SIL Open Font License 1.1 — 상용 게임 OK, 별도 승인 불필요.
- **다운로드**:
  - https://github.com/neodgm/neodgm/releases
  - https://github.com/neodgm/neodgm-pro
  - https://neodgm.dalgona.dev (공식 사이트)
- **분위기 매칭**: "시간이 멈춘 숲"의 정적 + 옛 시간 모티브와 잘 어울림. 단, 게임 본문보다는 OS/터미널 느낌이 강함.
- **Godot 4.x 노트**: TTF로 16px 또는 32px(2배)에서만 사용. 비정수배 금지.

#### Mulmaru (물마루) — **두꺼운 본문이 필요할 때**
- **디자이너**: mushsooni
- **콘셉트**: 한국어 인디 게임 번역 시 마땅한 한글 픽셀 폰트가 없어서 직접 제작. **명시적으로 "게임용"** 으로 디자인됨.
- **사이즈**: 12px (9pt)에서 최적. 정수배 권장.
- **변형판**: 가변폭(Mulmaru) / 고정폭(Mulmaru Mono)
- **한글 커버리지**: 11,172자 + 호환 자모 51자 = 11,937자. 라틴/키릴/일본 가나 포함.
- **라이선스**: SIL Open Font License 1.1.
- **다운로드**: https://github.com/mushsooni/mulmaru
- **특징**: 두꺼운 세로 stroke + 둥근 모서리. Galmuri보다 **무게감/판독성이 강함**. 작은 화면에서 본문이 더 잘 읽힘.

#### DOSSaemmul (도스샘물)
- **디자이너**: leedheo (https://github.com/hurss/fonts)
- **사이즈**: 16x16 BDF + TTF
- **라이선스**: MIT (귀속 표기 권장: "글꼴(폰트)로 도스샘물체(leedheo 제작)를 사용하였습니다")
- **상용 OK**: 가능
- **노트**: 한자(CJK Ext A/B) 광범위 포함. 글자 수 24,867. 한글 부분은 정사각 16x16으로 다소 단조로움. **본 게임에는 미적 매칭이 약함** — 1순위 후보 아님.

#### 기타 보조 후보
- **Silver** (Poppy Works, itch.io): 라틴/한자/한글 등 폭넓은 다국어 지원. 한글은 보조 수준이라 본격 본문용으론 부족.
- **LanaPixel** (OpenGameArt): 다국어 픽셀 폰트, 한글 지원. 8px급. 본문 가독성 부족.
- **Seven Fifteen** (Burpy Fresh): 7x15 모노스페이스 + 자모 일부. 한글 본격 지원 아님.

---

## 3. 유료 한글 픽셀 폰트

### 3.1 Yoon px 시리즈 (Yoon Design Group)

| 폰트 | 특징 | 한글 |
|---|---|---|
| **Yoon px Pixman** | 발랄/유쾌, 비스듬한 세로획 | 11,172자 |
| **Yoon px Furgayo** | "가/니/어/시" 등에 하트 장식, 90~00년대 미니홈피 정서 | 11,172자 |
| **Yoon px Pixelbatang** | 픽셀 명조 — 본문 진중함 | 11,172자 |
| **Yoon px Windowgothic** | 윈도우 비트맵 시절 고딕 톤 | 11,172자 |

- **유통**: Adobe Fonts 노출. 단 **Adobe Fonts 라이선스는 게임 임베딩(소프트웨어 안에 폰트 파일 포함) 금지** — 게임 안에 라이브 폰트로 쓰려면 Yoon Design과 **별도 라이선스 계약** 필요.
- **가격대**: Yoon Design은 개별 폰트 단품 라이선스 + 패키지 라이선스를 운용. 게임 임베딩 라이선스는 일반적으로 **연간 또는 영구** 분리 과금 (인디 기준 추정 30~150만원 단위, 폰트당). 정식 견적은 직접 문의 필요.
- **사용 가능 케이스**:
  1. **로고/타이틀 이미지로만 사용**: PNG로 래스터화 후 정적 이미지로 게임에 포함 → Adobe Fonts 라이선스 범위 내 가능.
  2. **게임 본문 동적 렌더링**: Yoon Design과 직접 라이선스 계약 체결 필수.

### 3.2 Sandoll
- 한국 최대 폰트 회사 (40년, 600+ 폰트). 픽셀 전용은 빈약. SanDollMisaeng 등 손글씨/디스플레이 폰트가 강세.
- 게임용 픽셀 폰트로는 마땅한 후보 부재.

### 3.3 결론
유료 옵션은 **로고용 한 컷**으로만 합리적. 게임 본문 임베딩 라이선스는 인디 1~2년 출시 일정/예산에 비해 **ROI 낮음**. 무료 OFL이 디자인 품질·라이선스 명확성·커뮤니티 검증 모두 우월.

---

## 4. 직접 제작 비용 분석

### 4.1 글리프 수 결정

| 접근법 | 글리프 수 | 커버리지 | 작업량 |
|---|---|---|---|
| 자모 합성 (Jamo composition) | 19 초성 + 21 중성 + 28 종성 = **68자** | 이론상 11,172자 전부 | **Hangul Shaping 엔진 필요** — 게임 엔진 텍스트 렌더러가 OpenType GSUB/GPOS Hangul shaping을 지원해야 함. Godot 기본 TextServer Advanced(HarfBuzz)는 지원하지만, 비트맵 폰트에선 직접 합성 코드 필요. 실용성 낮음. |
| KS X 1001 완성형 | **2,350자** | 현대 한글 ~99%, 일상 표기 거의 전부 | 현실적 최소 세트 |
| Adobe-KR-0+1 | 4,358자 | KS X 1001 + 보강 (희귀 음절) | Galmuri/Mulmaru가 채택한 절충 |
| 유니코드 완성형 | **11,172자** | 100% (이론상 모든 현대 한글) | 풀 커버리지 |

> **권장 최소**: 게임 텍스트(대사/UI/시스템 메시지)에 등장하는 모든 한글 **2,350자 KS X 1001**.
> 등장하지 않는 음절(예: "뙮", "쀓")이 우연히 나타나면 폴백 폰트 필요.

### 4.2 시간 견적 (1인 픽셀 아티스트 기준)

| 단계 | 작업 | 시간 |
|---|---|---|
| 자모 디자인 | 19+21+28 = 68 자모, 6 변형 (초·중·종 위치별) → 약 **150~200 자모 글리프** | 30~50시간 |
| 라틴/숫자/기호 | ASCII + 한글 문장부호 + 게임 기호 (~120자) | 10~20시간 |
| 합성 음절 검수/수정 | 2,350자 한 자씩 눈으로 확인, 충돌·끊김 수정 (자모 합성 자동 생성 후) | **150~250시간** |
| 폰트 빌드/툴링 | Glyphs / FontForge / BitFontMaker2 + 자동 합성 스크립트 | 20~40시간 |
| Godot 통합/검수 | TTF/.fnt 굽기, 게임 내 실 텍스트 검수 | 10~20시간 |
| **합계 (KS X 1001 2,350자)** | — | **220~380시간** |
| 11,172자 풀 커버리지 추가 | 추가 8,800여 자 자동 생성 + 부분 검수 | +50~100시간 |

> **시간당 글리프 환산**: 단순 평균 8~12 자/시 (자모 합성 자동화 가정). 100% 수동이면 **1~3 자/시간**으로 떨어져 1,000시간+ 소요.

### 4.3 툴링 옵션

| 툴 | 가격 | Hangul 지원 | 적합도 |
|---|---|---|---|
| **BitFontMaker2** (Pentacom, 웹) | 무료 | 자모 단위 가능, 자동 합성은 별도 스크립트 | 1차 자모 디자인용 |
| **YAL's Pixel Font Converter** | 무료 (yal.cc/tools/pixel-font/) | BitFontMaker2 호환 + 다양한 출력 포맷 | 변환/내보내기용 |
| **Glyphs / Glyphs Mini** (macOS) | $300 / $50 | **자모 자동 합성 기능 내장** ("Hangul Composition") | macOS 사용 시 최선 |
| **FontForge** | 무료 | Hangul 합성 가능하나 수동 스크립팅 필요 | Linux/Windows 무료 옵션 |
| **Aseprite + 스프라이트시트 → BMFont 변환** | $20 + 스크립트 | 직접 그리기 가능, 11,172 자 그리는 건 비현실적 | 작은 폰트(라틴) 또는 로고용 |
| **Fontstruct** (웹) | 무료 | 한글 가능 (커뮤니티 사례 존재) | 모듈식 디자인 적합 |

### 4.4 Godot 4.x 폰트 통합 워크플로

#### TTF (벡터 픽셀 폰트, OFL 폰트 권장 경로)
1. `assets/fonts/`에 .ttf 배치 → Godot 자동 임포트 (`FontFile` 리소스).
2. 임포트 설정:
   - **Antialiasing**: Disabled
   - **Hinting**: None
   - **Subpixel Positioning**: Disabled
   - **Generate Mipmaps**: Off
3. `Theme` 또는 `Label.add_theme_font_override("font", preload("..."))`로 적용.
4. `font_size`는 폰트의 디자인 사이즈 정수배(12, 24, 36...)만 사용.

#### BMFont .fnt (직접 제작 비트맵 폰트)
- Godot 4.x에서 `.fnt` 임포트가 가능하지만 **알려진 이슈 다수** (godot#74200). 일부 환경에서 한글 같은 큰 코드포인트 매핑이 깨짐.
- **권장 우회 경로**: 직접 제작해도 **TTF로 빌드**해서 Godot에 넣는 것이 안정적. FontForge로 비트맵 → TTF 임베디드 비트맵 변환.
- 대안: `martin-senges/font-generator-for-godot-4` (itch.io) 같은 서드파티 툴.

---

## 5. 평가 매트릭스 (의사결정용)

| 기준 | 직접 제작 | 무료 OFL (Galmuri 등) | 유료 (Yoon px 임베딩 라이선스) |
|---|---|---|---|
| **라이선스 위험** | 0 (자기 자산) | 매우 낮음 (OFL 표준) | 낮음~중 (계약서 정독 필요) |
| **시각적 유니크함** | 높음 (게임 정체성) | 낮음 (다수 게임이 동일 폰트) | 중 (Adobe Fonts에서 보지만 게임에선 드묾) |
| **개발 시간 비용** | **220~380시간** | ~1시간 (다운로드+임포트) | ~10시간 (계약+세팅) |
| **품질/판독성** | 디자이너 역량 의존 (위험) | 매우 높음 (수년간 다듬어짐) | 매우 높음 |
| **출시 일정 영향** | 1~2개월 추가 | 영향 없음 | 영향 없음 |
| **Steam 출시 안전성** | 100% | OFL 준수 시 100% | 계약 범위 확인 필요 |
| **커뮤니티 기여 회수** | 직접 OFL 공개 시 가능 | — | — |

---

## 6. 최종 추천

### 6.1 메인 시나리오: **Galmuri 채택 + 로고만 직접 제작**

| 용도 | 폰트 | 사이즈 |
|---|---|---|
| 본문 대사/시스템 메시지 | **Galmuri11** | 12px (저해상 640x360에서 24px 표시) |
| HUD 큰 숫자/제목 | **Galmuri14** | 15px (30px 표시) |
| 작은 보조 라벨 | **Galmuri9** 또는 Galmuri7 | 10px / 8px |
| 게임 로고 / 타이틀 화면 | **Aseprite 직접 제작** (4글자 "시간이 멈춘 숲") | 임의 크기 |
| 폴백 (Galmuri 누락 글리프) | **Mulmaru** | 12px |

**근거**:
- OFL 1.1 — Steam 출시에 법적 위험 0.
- 닌텐도 DS 베이스 디자인 → 메트로배니아 픽셀 게임 미적 합치도 최상.
- 11,172자 전체 글리프 보유 → 어떤 한글 텍스트도 깨짐 없음.
- 본 프로젝트의 한국어 단어("시간", "그림자", "땅거미", "거점")는 모두 핵심 2,355자 디자인 영역 안 → 최고 품질 글리프.
- 6종 사이즈 변형 → HUD/본문/제목/팁 텍스트 모두 동일 폰트 패밀리로 통일감 확보.
- 폴백으로 Mulmaru 추가 시 Galmuri7 작은 사이즈에서 빠진 음절(4,358자 외)을 12px로 메꿈.

### 6.2 차선 시나리오: **Neo둥근모 + Galmuri 혼용**

"시간이 멈춘 숲"의 멈춰버린 시간 / 옛 PC 시대 향수 콘셉트를 살리려면 **Neo둥근모를 기본으로** 가는 것도 강한 선택. DOS 시절 모노톤 둥근맛이 정적인 분위기와 매칭됨. 단 게임 본문보다 OS/노트 장면 같은 진단 화면 / 일기 텍스트에 더 적합 — UI별 분리 적용을 권장.

### 6.3 비추천 시나리오: 직접 제작
- 1인 개발 + AI 코드 + 사용자 픽셀 아트 분담 구조에서, **220~380시간**을 폰트에 쓰는 것은 본 게임의 전체 아트 예산(스프라이트, 타일, 이펙트, 보스)에서 큰 비중을 잠식.
- Galmuri/Neo둥근모가 이미 인디 한국 게임 표준에 가까워 "다른 게임과 구별 안 됨" 우려는 실제론 낮음 — 색감/배경/UI 프레임으로 차별화 가능.
- **직접 제작이 정당화되는 유일한 경우**: 폰트 자체가 게임의 비주얼 아이덴티티 핵심일 때 (예: 폰트가 "그림자 시스템"의 가독성 트릭에 직접 관여). 현재 GDD엔 그런 요건 없음.

### 6.4 액션 아이템

1. [ ] `assets/fonts/` 폴더 생성, `galmuri/` 하위에 Galmuri11/14/9 TTF 배치.
2. [ ] `data/themes/main_theme.tres` 또는 Autoload `UIRoot`에서 기본 폰트로 Galmuri11 등록.
3. [ ] 임포트 설정 4종(Antialias/Hinting/Subpixel/Mipmap) 일괄 비활성화.
4. [ ] OFL 라이선스 텍스트를 `LICENSES/Galmuri-OFL.txt`로 동봉 + 게임 크레딧/옵션 화면에 폰트 출처 표기.
5. [ ] (선택) Mulmaru 폴백 등록 — `FontVariation` 또는 Theme의 fallback 체인 사용.
6. [ ] 게임 로고 스프라이트만 Aseprite로 별도 제작.

---

## 7. 라이선스 컴플라이언스 체크리스트 (Steam 출시 시)

- [ ] OFL 1.1 라이선스 전문(`OFL.txt` 또는 `LICENSE`) 게임 빌드에 포함 (예: `<game_dir>/LICENSES/`).
- [ ] 게임 크레딧 또는 옵션 → 정보 화면에 폰트명·디자이너·라이선스 명시.
  - 예: "Galmuri11 by Quiple, licensed under SIL Open Font License 1.1"
- [ ] 폰트 파일명(.ttf)은 임의 변경 금지. 변경 시 OFL "Reserved Font Name" 조항 위반 가능.
- [ ] 폰트를 단독으로 판매하지 않음 (OFL 핵심 조항).
- [ ] 폰트를 수정해서 재배포할 일이 있으면 같은 OFL로 재배포 + 이름 변경.

---

## 8. 출처

- Galmuri GitHub: https://github.com/quiple/galmuri
- Galmuri 공식: https://quiple.dev/font/galmuri
- Neo둥근모 GitHub: https://github.com/neodgm/neodgm
- Neo둥근모 Pro: https://github.com/neodgm/neodgm-pro
- Neo둥근모 공식: https://neodgm.dalgona.dev
- Mulmaru GitHub: https://github.com/mushsooni/mulmaru
- DOSSaemmul: https://github.com/hurss/fonts
- SIL Open Font License: https://openfontlicense.org/
- Noonnu (한국 무료 폰트 모음): https://noonnu.cc
- Yoon px Pixman (Adobe Fonts): https://fonts.adobe.com/fonts/yoon-px-pixman
- Yoon px Furgayo: https://fonts.adobe.com/fonts/yoon-px-furgayo
- Adobe Fonts 라이선스 가이드: https://helpx.adobe.com/fonts/using/font-licensing.html
- Godot Pixel Font 가이드: https://not-jam.itch.io/not-jam-font-pack/devlog/749049/pixel-fonts-a-godot-tutorial
- Godot Bitmap Font 이슈: https://github.com/godotengine/godot/issues/74200
- Glyphs Hangul 디자인: https://glyphsapp.com/learn/creating-a-hangeul-font
- BitFontMaker2: https://www.pentacom.jp/pentacom/bitfontmaker2/
- YAL Pixel Font Converter: https://yal.cc/tools/pixel-font/
- Korean Hangul Display 효율: https://oberg.org/posts/hangul/
- Microsoft Hangul OpenType 개발: https://learn.microsoft.com/en-us/typography/script-development/hangul
