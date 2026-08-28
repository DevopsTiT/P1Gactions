# Verify today's complete packs — review before running
ls /Users/k/Work/AIProjects/Files/2026-08-28
ls /Users/k/Work/AIProjects/Files/2026-08-28/1-dynatrace-logs-pii-filter
ls /Users/k/Work/AIProjects/Files/2026-08-28/2-pic-style-answer-workflow
ls /Users/k/Work/AIProjects/Files/2026-08-28/3-generate-all-files-today
ls /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28
ls /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter
ls /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/2-pic-style-answer-workflow
ls /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/3-generate-all-files-today
find /Users/k/Work/AIProjects/Files/2026-08-28 -type f | sort
find /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28 -type f ! -name .DS_Store | sort
diff -rq /Users/k/Work/AIProjects/Files/2026-08-28/1-dynatrace-logs-pii-filter /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter || true
diff -rq /Users/k/Work/AIProjects/Files/2026-08-28/2-pic-style-answer-workflow /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/2-pic-style-answer-workflow || true
diff -rq /Users/k/Work/AIProjects/Files/2026-08-28/3-generate-all-files-today /Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/3-generate-all-files-today || true
