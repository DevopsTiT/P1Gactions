# Glossary

| Term | What it means |
| --- | --- |
| Scanned data | Bytes Dynatrace read for your filters. Large scan + 0 rows means a later filter rejected everything. |
| contains | Substring match inside the log line. Safer for class names like AXACleansingAddressBP. |
| matchesRegex | Pattern match. Easy to break when `\s` is doubled or mangled on paste. |
| matchesPhrase | Whole-token match. Fails when the token is longer (Address vs AddressBP). |
| host group | Dynatrace grouping of hosts; MDM APP id ends with CUSTMDMGM_E_PRD_T_APP. |
