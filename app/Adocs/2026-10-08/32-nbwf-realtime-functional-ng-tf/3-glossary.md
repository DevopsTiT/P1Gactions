# NBWF Glossary

| Term | What it means | Why you care |
|---|---|---|
| NBWF | Application name in the configuration lookup | Selects the NBWF projects |
| group-jobs | Real Time group job | Its result decides OK or NG |
| applications | Functional job | Grouped with the Real Time job |
| Alert Status Manager | Splunk action that emails and can page | Tells you the alert matters, so severity is high |
| rt_fails | Count of non-SUCCESS Real Time runs in the window | 2 or more with no SUCCESS opens the problem |
