@echo off
:: Zen PDF Viewer — Windows launcher wrapper
:: Double-click a PDF that is associated with this file, or run:
::   launch.bat C:\path\to\file.pdf
::   launch.bat https://example.com/doc.pdf
::
:: This wrapper calls launch.ps1 in the same directory.
:: Requirements: Python 3 on PATH, PowerShell 5+.

setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%SCRIPT_DIR%launch.ps1" -Path "%~1"
endlocal
