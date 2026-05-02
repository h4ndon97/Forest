@echo off
REM Aseprite export 더블클릭 래퍼
REM 전체 art_source/ 처리 (mtime 비교 — 변경된 것만 export)
REM
REM 더블클릭 시 PowerShell 스크립트를 호출하고 결과를 확인할 수 있게 일시정지.
REM 특정 영역만 처리하거나 옵션이 필요하면 PowerShell에서 직접 호출:
REM   .\tools\export_aseprite.ps1 player
REM   .\tools\export_aseprite.ps1 -Force

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0export_aseprite.ps1"
echo.
pause
