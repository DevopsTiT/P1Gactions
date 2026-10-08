# Function Reconfirm Glossary

| Term | What it means | Why you care |
|---|---|---|
| Functional job | A Jenkins `applications*` job that tests app features | This alert counts these results |
| Real Time job | A Jenkins `group-jobs*` job | Counted but not judged here |
| pager_duty = "0" | The lookup flag for apps that don't page | Decides which apps this alert covers |
| Alert Status Manager | A Splunk action that mails on state change | Explains why `event > 0` is not noisy in Splunk |
| In-place update | Same resource name, so apply changes the existing detector | Apply from one folder only |
