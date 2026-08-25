# Windows PowerShell / cmd only — run on the Windows PC (not macOS).
# Related guide: Adocs/2026-08-25/5-install-cursor-windows-cli/5-install-cursor-windows-cli.md
winget --version
winget search Cursor
winget show --id Anysphere.Cursor --exact
winget install --id Anysphere.Cursor --exact
winget install --id Anysphere.Cursor --exact --scope user
winget install --id Anysphere.Cursor --exact --silent --accept-package-agreements --accept-source-agreements
winget install --id Anysphere.Cursor --exact --scope user --silent --accept-package-agreements --accept-source-agreements
winget upgrade --id Anysphere.Cursor --exact
choco --version
choco search cursoride
choco install cursoride -y
scoop --version
Get-Command winget
Test-NetConnection cursor.com -Port 443
Invoke-WebRequest -Uri "https://cursor.com/download" -Method Head
# After downloading User installer from https://cursor.com/download — replace path/version:
# Start-Process -FilePath "$env:USERPROFILE\Downloads\CursorUserSetup-x64.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait
dir "$env:LOCALAPPDATA\Programs\cursor"
