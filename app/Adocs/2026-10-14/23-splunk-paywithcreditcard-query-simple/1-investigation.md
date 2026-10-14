# Splunk PayWithCreditCard Query Simple Investigation

| Step | Plain English |
|---|---|
| 1 | Pick the AMP backend app and the last hour. |
| 2 | Turn `\"` into `"`. |
| 3 | Delete leftover `\`. |
| 4 | Read the JSON into fields. |
| 5 | Keep credit-card payment calls that finished. |
