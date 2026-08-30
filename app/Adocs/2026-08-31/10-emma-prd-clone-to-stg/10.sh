# Review before run. STG URLs only. Never edit or break KTA - TH EMMA PRD.
echo "Open dashboard KTA - TH EMMA PRD read-only; do not save edits on PRD"
echo "Duplicate dashboard to KTA - TH EMMA STG or L1-Health-STG"
echo "Edit STG copy: set MZ/tag filter to STG; add Markdown STAGING COPY"
echo "Retarget Overview Web Services Infrastructure tiles to STG entities"
echo "Mobile: keep out of scope if Permission denied; do not block trial"
echo "Add gap tiles on STG: Logs DB L1 Markdown Architecture"
curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "https://STG_URL/health"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo"; done
curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo?force_error=1"
echo "Create HTTP synthetic STG-app-health against https://STG_URL/health"
echo "Run STG-only failure drill; confirm Failure rate and 99th RT and Problems move"
echo "Export STG dashboard JSON after checklist pass"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/10-emma-prd-clone-to-stg"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/10-emma-prd-clone-to-stg/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/10-emma-prd-clone-to-stg/"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git status
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git add "app/Adocs/2026-08-31/10-emma-prd-clone-to-stg"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git commit -m "docs: add EMMA PRD dashboard clone-to-STG guide"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git push
