# Windows only — run on the AD-joined PC (PowerShell or cmd). Do not bypass GPO/AV.
# Official download page (browser):
start https://cursor.com/download
# Open the download page in default browser (PowerShell):
Start-Process "https://cursor.com/download"
# After User install, typical app folder (verify path exists):
dir "%LOCALAPPDATA%\Programs\cursor"
# PowerShell equivalent:
Get-ChildItem "$env:LOCALAPPDATA\Programs\cursor"
# After System install, typical app folder:
dir "%ProgramFiles%\cursor"
# PowerShell equivalent:
Get-ChildItem "$env:ProgramFiles\cursor"
# Check if Software Center exists (ConfigMgr client):
dir "C:\Windows\CCM\ClientUX\SCClient.exe"
# Open Company Portal if installed (Microsoft Store app id varies by tenant):
start ms-companyportal:
