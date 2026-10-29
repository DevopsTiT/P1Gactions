# Glossary

| Term | What it means |
|---|---|
| PODFrozen | The alert fires when the number of names is not the expected number. |
| `Message` | How many different pod or host names were seen. |
| `unit` | The one name counted for a log. Pod name when it matches, otherwise host name. |
| `countDistinct` | Counts different values. Many lines from one pod count once. |
| Expected number | 4, 3, 2, or 1, depending on the alert. |
| Text check | Returns the log lines that contain a fixed sentence or error code. |
| Quiet result | 0 records. For PODFrozen, the name count matched. For a text check, the phrase was absent. |
