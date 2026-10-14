# CC ESBv4 Ebroker Silent Apps Investigation

| What was checked | Finding |
|---|---|
| #69, #74 | Wildcards inside quoted phrases. Split into parts. |
| #67 | Log level pulled with a regex. Rebuilt with `parse`. |
| #72 | Subsearch on request ID. Rebuilt with `lookup`. |
| #76 | Sourcetype version of #18. App name replaces sourcetype. |
| Blurry text | `NoUpdatePaymentError`, `ottif`, `localhost:8082` need checking. |
| #76 end | Cut off at the bottom of the screenshot. |
