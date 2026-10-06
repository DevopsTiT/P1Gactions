# Glossary

| Term | What it means | Why you care |
|---|---|---|
| `fieldsAdd` | DQL command that adds a new column to every row | Used here to add a constant grouping value |
| Constant field | A column with the same value on every row | Makes all rows look like "the same problem" |
| Violation | One row returned by a Records detector query | Many violations can belong to one problem |
| `alertIdentityFields` | Detector setting naming the grouping field | Controls how many problems and emails you get |
| Problem | Dynatrace's open alert that sends the notification | You want one per batch run, not one per line |
