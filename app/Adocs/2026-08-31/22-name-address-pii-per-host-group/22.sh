open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/22-name-address-pii-per-host-group.dql"
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/22-name-only-per-host-group.dql"
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-address-only-per-host-group.dql"
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/22-name-address-pii-per-host-group.md"
cp "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/"*.md "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/22-name-address-pii-per-host-group/"
cp "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/"*.dql "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/22-name-address-pii-per-host-group/"
cp "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/22.sh" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/22-name-address-pii-per-host-group/"
cp "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/22-name-address-pii-per-host-group/"*follow.txt "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/22-name-address-pii-per-host-group/"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git status
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git add app/Adocs/2026-08-31/22-name-address-pii-per-host-group
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git commit -m "Add name/address PII DQL per host group"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git push
