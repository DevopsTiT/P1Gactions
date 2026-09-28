# Result

| Change | Where |
|---|---|
| Impact and urgency fixed to 4, so priority is 4 - Low | OPEN prepare-payload |
| Business service and offering sys_ids looked up by name | OPEN post-silva-incident-http |
| POST sends the sys_ids | OPEN post-silva-incident-http |
| PATCH re-applies the sys_ids after create | OPEN post-silva-incident-http |
| Result shows serviceLookup and serviceFix | OPEN post-silva-incident-http |
| Switch to stop sending the CI | OPEN settings (`SEND_CONFIGURATION_ITEM`) |
| CLOSE | No change |

Next: import OPEN, trigger a test problem, open the post-silva-incident-http result and check serviceLookup and serviceFix.
