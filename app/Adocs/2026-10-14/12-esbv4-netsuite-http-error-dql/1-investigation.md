# ESBv4 NetSuite HTTP Error Investigation

| What was checked | Finding |
|---|---|
| SPL shape | One index plus one quoted phrase. |
| `index=esbv4` | No Dynatrace index. Needs a field check. |
| Phrase case | Splunk ignores case. DQL uses `caseSensitive:false`. |
| URL in phrase | Contains a NetSuite account number. Not a secret, kept as in the SPL. |
