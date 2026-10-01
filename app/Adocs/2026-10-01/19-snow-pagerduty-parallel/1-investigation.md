# Investigation

| What was checked | Evidence |
|---|---|
| OPEN v7 trigger-pagerduty | Used to depend on post-silva-incident and read inc.number / inc.url |
| PREVIEW v7 preview-pagerduty | Used to depend on preview-silva-incident and read its verdict |
| After change | Both PD tasks list only build-payload as predecessor; no reads of the SILVA task result remain |
| Lint | No linter errors in either file |
