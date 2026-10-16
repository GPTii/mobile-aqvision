@echo off
REM Double-click file nay de cai toan bo moi truong cho AQPConnect (xem SETUP.md).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
echo.
pause
