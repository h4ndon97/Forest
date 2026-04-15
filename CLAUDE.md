# 시간이 멈춘 숲 — 프로젝트 규칙

> 이 문서는 Claude Code가 이 프로젝트에서 작업할 때 반드시 따라야 할 규칙을 정의한다.

---

## 1. 프로젝트 개요

- **장르**: 2D 픽셀아트 메트로배니아 (Godot 4.x, GDScript only)
- **개발 체제**: 1인 개발 (코드: AI, 아트: 사용자)
- **설계 문서**: GDD.md (마스터) + 시스템별 상세 문서 (STORY.md, CORE_SYSTEMS.md 등)
- **아트**: Aseprite → 스프라이트 시트 PNG → Godot

---

## 2. 아키텍처 원칙

### 2.1 스크립트 크기 제한
- **단일 스크립트 300줄 초과 금지**
- 300줄 근접 시 역할별로 분리 (헬퍼, 컴포넌트, 별도 노드)
- 분리 기준: 하나의 스크립트 = 하나의 책임

### 2.2 시스템 분리
- 각 게임 시스템은 **독립 Autoload**로 구성 (TimeSystem, ShadowSystem, CombatSystem 등)
- 시스템 간 직접 참조 금지 — **Signal 기반 통신**만 허용
- 시스템이 다른 시스템의 내부 상태를 직접 읽지 않음
- 필요 시 이벤트 버스(EventBus Autoload) 패턴 사용

### 2.3 씬 구성
- 씬은 **작고 재사용 가능**하게 구성
- 엔티티 = 여러 작은 노드/컴포넌트의 조합 (Composition over Inheritance)
- 루트 노드에 모든 로직 넣지 말 것 — 역할별 자식 노드로 분배

### 2.4 데이터 분리
- 게임 데이터(능력치, 아이템 정보 등)는 **Resource (.tres)** 파일로 관리
- 스크립트에 데이터 하드코딩 금지
- data/ 폴더에 리소스 파일 집중

### 2.5 네이밍 컨벤션
- **폴더**: snake_case (소문자)
- **씬 파일 (.tscn)**: PascalCase (예: PlayerCharacter.tscn)
- **스크립트 (.gd)**: snake_case (예: player_character.gd)
- **리소스 (.tres)**: snake_case (예: sword_basic.tres)
- **시그널**: past_tense (예: health_changed, time_stopped)
- **상수**: UPPER_SNAKE_CASE
- **변수/함수**: snake_case

---

## 3. Godot 컨벤션

### 3.1 필수 설정
- 텍스처 필터링: Nearest (프로젝트 전역)
- 기본 해상도: 640x360, 스케일링 3배 → 1080p
- 타일 크기: 64x64
- 그림자: 스프라이트 기반 (Light2D/Shadow2D 미사용)
- 분위기: CanvasModulate / 등불: PointLight2D

### 3.2 Autoload 등록 규칙
- src/systems/ 하위의 메인 스크립트만 Autoload로 등록
- Autoload 이름 = 폴더명의 PascalCase (예: time/ → TimeSystem)

### 3.3 입력 처리
- InputMap에 액션 등록 후 사용 (하드코딩된 키 입력 금지)
- 입력 처리는 해당 엔티티의 전용 스크립트에서만

---

## 4. GDD 준수

- 새 기능 구현 전, 해당 시스템의 **설계 문서를 반드시 먼저 읽을 것**
- 설계 문서에 "확정"으로 표시된 항목은 그대로 구현
- "미결"로 표시된 항목은 구현 전 사용자에게 확인
- 구현 중 설계와 다른 판단이 필요하면 사용자에게 먼저 제안

---

## 5. 에이전트 자동 호출 규칙

아래 조건에 해당하면 해당 에이전트를 **자동으로 호출**한다. 사용자의 별도 지시 없이도 실행한다.

### Architect (설계 에이전트)
- **트리거**: 새 시스템이나 주요 기능 구현을 시작할 때
- **동작**: 폴더 구조, 씬 분할, 시그널 설계, 의존성 맵을 먼저 산출
- **규칙**: Architect의 설계 없이 새 시스템 코드 작성 금지

### Code Reviewer (코드 리뷰 에이전트)
- **트리거**: 코드 작성/수정 작업이 완료된 후
- **동작**:
  1. 아키텍처 원칙 준수 여부 검증 (섹션 2 기준)
  2. `gdlint` 로 수정된 파일 린트 검사 (네이밍, 미사용 인자 등)
  3. `gdformat --check` 로 코드 스타일 일관성 확인
  4. 위반 사항 리포트
- **규칙**: 리뷰 결과에 위반 사항이 있으면 커밋 전 수정

### QA (품질 검증 에이전트)
- **트리거**: 시스템 구현 완료 시 또는 여러 시스템 통합 시
- **동작**:
  1. GDD/설계 문서와 구현 대조, 로직 정합성 검증, 엣지 케이스 점검
  2. Godot CLI 로드 테스트 (`--headless --quit`) 로 프로젝트 정상 로드 확인
  3. 에러 로그 분석 및 보고
- **규칙**: 불일치 또는 로드 에러 발견 시 사용자에게 보고 후 수정

### Doc Manager (문서 관리 에이전트)
- **트리거**: 구현 중 설계 변경이 발생했을 때
- **동작**: 관련 설계 문서(GDD.md + 상세 문서) 갱신, 미결 사항 업데이트
- **규칙**: 코드 변경만 하고 문서를 안 바꾸는 상황 방지

### Art Spec Writer (아트 명세서 에이전트)
- **트리거**: 시각 요소가 포함된 기능 구현이 완료되었을 때
- **동작**:
  1. 해당 요소의 아트 명세서 생성 (캔버스, 애니메이션, 프레임, 태그명 등)
  2. `.ase` / `.aseprite` 파일이 존재하면 Aseprite CLI로 스프라이트 시트 내보내기 수행
     - `aseprite --batch input.ase --sheet output.png --data output.json`
  3. 출력물을 `assets/sprites/` 하위 적절한 폴더에 배치
- **규칙**: ART_PIPELINE.md의 규격 준수

---

## 6. 폴더 구조

```
Forest/
├── project.godot
├── src/
│   ├── systems/           # Autoload 게임 시스템
│   │   ├── time/          # 시간 시스템 (조작, 흐름, 사이클)
│   │   ├── shadow/        # 그림자 시스템 (크기, 적 강도)
│   │   ├── combat/        # 전투 시스템 (콤보, 데미지)
│   │   ├── enemy/         # 적 시스템 (생성, 잔류, 타입)
│   │   ├── dusk_spider/   # 땅거미 시스템
│   │   ├── stage/         # 스테이지 시스템 (클리어, 잠금)
│   │   ├── growth/        # 성장 시스템 (포인트, 투자)
│   │   ├── inventory/     # 아이템/장비 시스템
│   │   ├── skill/         # 스킬 시스템 (트리, 슬롯)
│   │   └── event_bus/     # 이벤트 버스 (시스템 간 시그널)
│   ├── entities/          # 게임 엔티티
│   │   ├── player/        # 플레이어 캐릭터
│   │   ├── enemies/       # 적 (베이스 + 서브타입)
│   │   ├── bosses/        # 보스
│   │   ├── npcs/          # NPC
│   │   └── objects/       # 환경 오브젝트 (거울, 렌즈 등)
│   ├── world/             # 월드/맵
│   │   ├── stages/        # 스테이지 씬
│   │   ├── checkpoints/   # 거점 씬
│   │   ├── tiles/         # 타일셋/타일맵
│   │   └── world_map/     # 월드맵 UI
│   ├── ui/                # UI
│   │   ├── hud/           # 인게임 HUD
│   │   ├── menus/         # 메뉴 (타이틀, 설정, 장비)
│   │   └── common/        # 공통 UI 컴포넌트
│   └── common/            # 공통 유틸리티
│       ├── constants.gd
│       └── helpers/
├── assets/                # 아트 리소스
│   ├── sprites/           # 스프라이트 시트
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── bosses/
│   │   ├── objects/
│   │   └── effects/
│   ├── tiles/             # 타일 이미지
│   ├── ui/                # UI 아트
│   └── backgrounds/       # 배경
├── data/                  # 게임 데이터 (.tres 리소스)
│   ├── items/
│   ├── enemies/
│   ├── skills/
│   └── stages/
├── audio/                 # 사운드/음악
└── docs/                  # 설계 문서
    ├── GDD.md
    ├── STORY.md
    ├── CORE_SYSTEMS.md
    ├── STAGES.md
    ├── SKILLS.md
    ├── COMBAT.md
    ├── ENEMIES.md
    ├── BOSSES.md
    ├── WORLD_DESIGN.md
    ├── GROWTH.md
    ├── ITEMS.md
    ├── ART_PIPELINE.md
    └── art_specs/         # 아트 명세서 (에이전트가 생성)
```

---

## 7. CLI 도구 규칙

### 7.1 실행파일 경로
- **Godot 콘솔**: `C:/_H4ndon/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe`
- **Aseprite**: `C:/Program Files/Aseprite/Aseprite.exe`
- **gdlint / gdformat**: 시스템 PATH에 설치됨 (gdtoolkit 4.5.0)

### 7.2 코드 검증 (코드 수정/생성 후 자동 수행)
1. **gdlint** — 수정한 파일 대상 린트 검사
   - `gdlint src/systems/enemy/enemy_system.gd`
   - 네이밍 컨벤션, 미사용 인자 등 검출
2. **Godot 로드 테스트** — 프로젝트 전체 로드 확인
   - `godot --headless --path "c:/_H4ndon/Forest" --quit`
3. 에러 발생 시 사용자에게 전달하기 전에 **먼저 수정 시도**
4. 수정 불가능한 에러는 로그와 함께 사용자에게 보고

### 7.3 코드 포매팅
- **gdformat** — 코드 스타일 자동 정리 (필요 시 사용)
  - `gdformat src/systems/enemy/enemy_system.gd`

### 7.4 Aseprite 아트 파이프라인
- 사용자가 `.ase` / `.aseprite` 파일을 제공하면 CLI로 스프라이트 시트 내보내기 수행
  - `aseprite --batch input.ase --sheet output.png --data output.json`
  - `--split-tags` 로 애니메이션 태그별 분리 가능
- 출력 경로는 ART_PIPELINE.md 규격에 따라 `assets/sprites/` 하위에 배치

---

## 8. 커밋 규칙

- 커밋 메시지: 한국어 허용
- 시스템 단위로 커밋 (여러 시스템 한꺼번에 커밋 지양)
- 커밋 전 Code Reviewer 통과 필수
