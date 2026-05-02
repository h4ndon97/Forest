# Aseprite .ase / .aseprite → PNG (+ JSON) 일괄 export 스크립트
#
# 동작:
#   1. Lua 보조 스크립트(inspect_tags.lua)로 .aseprite의 태그 목록 추출
#   2-A. 태그 있음 → 태그별로 --frame-range 명시하여 1회씩 export
#        출력: <base>_<tag_lowercase>.png + .json
#   2-B. 태그 없음 → 전체를 단일 sheet로 export
#        출력: <base>.png + .json
#
# 폴더 구조 (둘 다 지원):
#   1. art_source/<영역>/<이름>.ase       → assets/sprites/<영역>/<이름>*.png  (분리 워크플로우)
#   2. assets/sprites/<영역>/<이름>.ase   → assets/sprites/<영역>/<이름>*.png  (in-place 워크플로우)
#
# 출력 파일명은 자동으로 소문자 변환됨 (CLAUDE.md §2.5 snake_case 규약).
#   예: Player.aseprite + tag "Idle_00" → player_idle_00.png
#
# 사용법 (PowerShell):
#   .\tools\export_aseprite.ps1                전체 처리 (mtime 비교, 변경된 것만)
#   .\tools\export_aseprite.ps1 player         player 영역만
#   .\tools\export_aseprite.ps1 -Force         전체 강제 재export
#   .\tools\export_aseprite.ps1 -NoData        JSON 미생성 (PNG만)
#   .\tools\export_aseprite.ps1 -NoLowercase   소문자 변환 비활성화
#
# Aseprite 실행파일 경로는 CLAUDE.md §7.1 기준:
#   C:\Program Files\Aseprite\Aseprite.exe

param(
    [Parameter(Position = 0)]
    [string]$Subdir = "",
    [switch]$Force = $false,
    [switch]$NoData = $false,
    [switch]$NoLowercase = $false
)

$ErrorActionPreference = "Stop"

# ─── 경로 설정 ──────────────────────────────────────────────────────────────
$ProjectRoot   = Split-Path -Parent $PSScriptRoot
$AsepriteExe   = "C:\Program Files\Aseprite\Aseprite.exe"
$ArtSource     = Join-Path $ProjectRoot "art_source"
$AssetsSprites = Join-Path $ProjectRoot "assets\sprites"
$InspectLua    = Join-Path $PSScriptRoot "inspect_tags.lua"

# ─── 사전 검증 ──────────────────────────────────────────────────────────────
if (-not (Test-Path $AsepriteExe)) {
    Write-Host "[ERROR] Aseprite 실행파일을 찾을 수 없습니다: $AsepriteExe" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $InspectLua)) {
    Write-Host "[ERROR] Lua 보조 스크립트가 없습니다: $InspectLua" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ArtSource)) {
    New-Item -ItemType Directory -Path $ArtSource -Force | Out-Null
}

# ─── 헬퍼: 태그 목록 추출 ────────────────────────────────────────────────────
function Get-AseTags {
    param([string]$AsePath)

    $tagFile = "$env:TEMP\ase_tags_$([System.IO.Path]::GetRandomFileName()).tsv"
    if (Test-Path $tagFile) { Remove-Item -LiteralPath $tagFile -Force }

    $env:ASE_TAG_OUT = $tagFile
    & $AsepriteExe --batch $AsePath --script $InspectLua | Out-Null
    Remove-Item Env:ASE_TAG_OUT -ErrorAction SilentlyContinue

    if (-not (Test-Path $tagFile)) { return @() }

    $tags = @()
    foreach ($line in Get-Content -LiteralPath $tagFile) {
        if ($line.Trim() -eq "") { continue }
        $parts = $line -split "`t"
        if ($parts.Count -ge 3) {
            $tags += [PSCustomObject]@{
                Name = $parts[0]
                From = [int]$parts[1]
                To   = [int]$parts[2]
            }
        }
    }
    Remove-Item -LiteralPath $tagFile -Force
    return ,$tags
}

# ─── 헬퍼: 단일 sheet export ─────────────────────────────────────────────────
function Export-Sheet {
    param(
        [string]$AsePath,
        [string]$SheetPath,
        [string]$DataPath,
        [int]$FrameFrom = -1,
        [int]$FrameTo = -1
    )

    $cmdArgs = @("--batch")
    if ($FrameFrom -ge 0 -and $FrameTo -ge 0) {
        $cmdArgs += "--frame-range"
        $cmdArgs += "$FrameFrom,$FrameTo"
    }
    $cmdArgs += $AsePath
    $cmdArgs += "--sheet-type"
    $cmdArgs += "horizontal"
    $cmdArgs += "--sheet"
    $cmdArgs += $SheetPath
    if ($DataPath) {
        $cmdArgs += "--data"
        $cmdArgs += $DataPath
    }

    & $AsepriteExe @cmdArgs | Out-Null

    # exit code 신뢰 못함 → 출력 파일 존재로 성공 판정
    return (Test-Path -LiteralPath $SheetPath)
}

# ─── 처리 대상 수집 ──────────────────────────────────────────────────────────
$InputRoots = @()
if ($Subdir) {
    $ArtSubdir    = Join-Path $ArtSource $Subdir
    $AssetsSubdir = Join-Path $AssetsSprites $Subdir
    if (Test-Path $ArtSubdir)    { $InputRoots += @{ Root = $ArtSource;     Search = $ArtSubdir;    InPlace = $false } }
    if (Test-Path $AssetsSubdir) { $InputRoots += @{ Root = $AssetsSprites; Search = $AssetsSubdir; InPlace = $true } }
} else {
    $InputRoots += @{ Root = $ArtSource;     Search = $ArtSource;     InPlace = $false }
    if (Test-Path $AssetsSprites) {
        $InputRoots += @{ Root = $AssetsSprites; Search = $AssetsSprites; InPlace = $true }
    }
}

$AllAseFiles = @()
foreach ($entry in $InputRoots) {
    $files = Get-ChildItem -Path $entry.Search -Recurse -Include "*.ase","*.aseprite" -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $AllAseFiles += [PSCustomObject]@{
            File    = $f
            Root    = $entry.Root
            InPlace = $entry.InPlace
        }
    }
}

if ($AllAseFiles.Count -eq 0) {
    Write-Host "[INFO] 처리할 .ase / .aseprite 파일이 없습니다." -ForegroundColor DarkGray
    exit 0
}

Write-Host "[INFO] 대상: $($AllAseFiles.Count) 파일" -ForegroundColor Cyan
Write-Host ""

$Processed = 0
$Skipped   = 0
$Failed    = 0

foreach ($entry in $AllAseFiles) {
    $AseFile = $entry.File
    $Root    = $entry.Root
    $InPlace = $entry.InPlace

    $RelativePath = $AseFile.FullName.Substring($Root.Length + 1)
    $RelativeDir  = Split-Path -Parent $RelativePath
    if ($InPlace) {
        $OutputDir = $AseFile.DirectoryName
    } else {
        $OutputDir = if ($RelativeDir) { Join-Path $AssetsSprites $RelativeDir } else { $AssetsSprites }
    }

    $BaseNameOriginal = [System.IO.Path]::GetFileNameWithoutExtension($AseFile.Name)
    $BaseName = if ($NoLowercase) { $BaseNameOriginal } else { $BaseNameOriginal.ToLower() }

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $loc = if ($InPlace) { "[in-place]" } else { "[mirror]" }
    Write-Host "  [scan] $loc $RelativePath" -ForegroundColor Cyan

    # 태그 추출
    $tags = Get-AseTags -AsePath $AseFile.FullName

    if ($tags.Count -eq 0) {
        # ── 태그 없음: 전체를 단일 sheet로 export ──
        $sheet = Join-Path $OutputDir "$BaseName.png"
        $data  = if ($NoData) { "" } else { Join-Path $OutputDir "$BaseName.json" }

        # mtime skip
        if (-not $Force -and (Test-Path -LiteralPath $sheet)) {
            $InTime  = $AseFile.LastWriteTime
            $OutTime = (Get-Item -LiteralPath $sheet).LastWriteTime
            if ($OutTime -gt $InTime) {
                Write-Host "    [skip] $BaseName.png" -ForegroundColor DarkGray
                $Skipped++
                continue
            }
        }

        if (Export-Sheet -AsePath $AseFile.FullName -SheetPath $sheet -DataPath $data) {
            Write-Host "    [ok]   $BaseName.png" -ForegroundColor Green
            $Processed++
        } else {
            Write-Host "    [fail] $BaseName.png" -ForegroundColor Red
            $Failed++
        }
    } else {
        # ── 태그 있음: 태그별로 --frame-range 명시 export ──
        Write-Host "    태그 $($tags.Count)개 발견" -ForegroundColor DarkGray
        foreach ($tag in $tags) {
            $tagName = if ($NoLowercase) { $tag.Name } else { $tag.Name.ToLower() }
            $sheet = Join-Path $OutputDir "${BaseName}_${tagName}.png"
            $data  = if ($NoData) { "" } else { Join-Path $OutputDir "${BaseName}_${tagName}.json" }

            # mtime skip
            if (-not $Force -and (Test-Path -LiteralPath $sheet)) {
                $InTime  = $AseFile.LastWriteTime
                $OutTime = (Get-Item -LiteralPath $sheet).LastWriteTime
                if ($OutTime -gt $InTime) {
                    Write-Host "    [skip] ${BaseName}_${tagName}.png  (frames $($tag.From)..$($tag.To))" -ForegroundColor DarkGray
                    $Skipped++
                    continue
                }
            }

            if (Export-Sheet -AsePath $AseFile.FullName -SheetPath $sheet -DataPath $data -FrameFrom $tag.From -FrameTo $tag.To) {
                Write-Host "    [ok]   ${BaseName}_${tagName}.png  (frames $($tag.From)..$($tag.To))" -ForegroundColor Green
                $Processed++
            } else {
                Write-Host "    [fail] ${BaseName}_${tagName}.png  (frames $($tag.From)..$($tag.To))" -ForegroundColor Red
                $Failed++
            }
        }
    }
}

# ─── 결과 ──────────────────────────────────────────────────────────────────
Write-Host ""
$Color = if ($Failed -gt 0) { "Yellow" } else { "Green" }
Write-Host "완료: $Processed 처리 / $Skipped 스킵 / $Failed 실패" -ForegroundColor $Color
if ($Failed -gt 0) {
    exit 1
}
