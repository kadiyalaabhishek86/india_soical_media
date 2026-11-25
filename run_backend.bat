@echo off
echo Starting FriendLoop backend on http://localhost:8000 ...
cd /d "%~dp0backend"
call .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
