# Run FriendLoop FastAPI Backend
Set-Location -Path "$PSScriptRoot\backend"
Write-Host "Starting FriendLoop backend on http://localhost:8000 ..." -ForegroundColor Cyan
& ".\.venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
