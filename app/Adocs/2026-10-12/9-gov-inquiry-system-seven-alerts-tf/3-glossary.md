# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces all seven alerts. |
| `parse` | Pulls values out of text using a pattern. | Extracts file name and counts. |
| `LD` | "Line data": skip any text. | Used before each label. |
| `INT` | Parse pattern for a whole number. | Reads the counts. |
| `WORD` | Letters, digits and underscore only. | May cut file names. |
| `NSPACE` | Everything up to the next space. | Safer for file names. |
| `alertIdentityFields` | Fields that group rows into one problem. | fileName gives one problem per file. |
| ND file | ND search result file. | Alert 1's input. |
| MDM | Master data management system response. | Alert 7's input. |
| pipitLINQ and Kyoto GW | External systems that send error files. | Sources for Alerts 5 and 6. |
