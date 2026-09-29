# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Predecessor | The task that must finish before this one | Sets the order of the three tasks |
| Condition state OK | The next task runs only if the previous one succeeded | A script error stops the chain |
| First match wins | The first source with a value is used and the rest are ignored | Explains every choice in the result |
| Hint | A tag recognised by its key name | Input for the SILVA lookup |
| SERVICE_MAP | Your own list mapping a trigram to a business service | The fix when SILVA cannot find the service by CI |
| steps | The list of every SILVA GET with status and match count | Tells you why something was not found |
| operational_status / install_status 1 | Active service / installed CI | Preferred when several rows match |
