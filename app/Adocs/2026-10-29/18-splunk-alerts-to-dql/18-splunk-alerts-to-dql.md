# Splunk Alerts To DQL

```
PODFrozen search
  one name per log
    pod name contains the index token → use k8s.pod.name
    else host name contains it → use host.name
  Message = how many different names
  Message equals the expected number → no row
  Message is any other number → one Total row
text search
  same name filter
  plus the exception text in content
  a row means the text was found
alfrescoacr
  drop names that contain alfrescoacr-batch
  expected number is 3
```

| Alert | Quiet when |
|---|---|
| `Prod_PnC_Alfrescoacr_BatchPODFrozen_High` | 4 names for `alfrescoacr-batch`. |
| `Prod_PnC_Agrex_PODFrozen_High` | 1 name for `agrex`. |
| `Prod_PnC_Alfrescoacr_PODFrozen_High` | 3 names for `alfrescoacr`, excluding `alfrescoacr-batch`. |
| Alfrescocollabsrv POD is frozen | 1 name for `alfrescocollabsrv`. |
| `Prod_PnC_BillingCenter_BatchPODFrozen_High` | 2 names for `bc2-batch`. |
| `Prod_PnC_PolicyCenter_BatchPODFrozenCheck_High` | 2 names for `pc2-batch`. |
| `Prod_PnC_BillingCenter_UIPODFrozen_High` | 2 names for `bc2-ui`. |
| `Prod_PnC_ContactManager_UIPODFrozen_High` | 2 names for `cm2-ui`. |
| `Prod_PnC_MailService_PODFrozen_High` | 1 name for `mailservice`. |
| BAU-4050 | No line contains the payment-request exception. |
| `Prod_PnC_BillingCenter_CCPaymentReimbursementCheck_High` | No line contains `errcode=E0105errinfo=E010500004`. |

## Summary

Each PODFrozen Splunk search counts hosts and returns a row only when the count is wrong. The matching DQL counts pod names or host names the same way. `Message` is that count. The two remaining searches return the log lines that contain a fixed phrase. Set the time picker to the same window you use in Splunk.

## Investigation

| Source | Finding |
|---|---|
| PODFrozen shape | `stats count by host`, drop `count`, `appendpipe` a Total row, keep it with `where NOT Message=N`. |
| Screen DQL shape | `summarize total = count(), by:{ host }` then `filter total != N`. That `total` is log lines per name. |
| `alfrescoacr` extra line | `filter not contains(..., "alfrescoacr-batch")`, so the batch pods are not part of the 3. |
| BAU-4050 | Splunk index `pc2-batch` plus the text `Creation of payment request in BC has thrown an exception`. |
| Reimbursement check | Splunk index `bc2-ui` plus `errcode=E0105errinfo=E010500004`. |

The PolicyCenter block’s Splunk index is `pc2-batch`. The DQL below uses `pc2-batch` on the pod name, the host name, and `log.source`.

## Result

`unit` is the pod name when that field contains the token. Otherwise it is the host name. `countDistinct(unit)` is `Message`.

### alfrescoacr-batch, expect 4

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(host.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 4
| fields host, Message
```

### agrex, expect 1

```
fetch logs
| filter contains(k8s.pod.name, "agrex", caseSensitive:false)
    or contains(host.name, "agrex", caseSensitive:false)
    or contains(log.source, "agrex", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "agrex", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "agrex", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 1
| fields host, Message
```

### alfrescoacr, expect 3

Names that contain `alfrescoacr-batch` are left out, so the batch pods are not counted in these 3.

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr", caseSensitive:false)
    or contains(host.name, "alfrescoacr", caseSensitive:false)
    or contains(log.source, "alfrescoacr", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr", caseSensitive:false) and not contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr", caseSensitive:false) and not contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 3
| fields host, Message
```

### alfrescocollabsrv, expect 1

```
fetch logs
| filter contains(k8s.pod.name, "alfrescocollabsrv", caseSensitive:false)
    or contains(host.name, "alfrescocollabsrv", caseSensitive:false)
    or contains(log.source, "alfrescocollabsrv", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescocollabsrv", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescocollabsrv", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 1
| fields host, Message
```

### bc2-batch, expect 2

```
fetch logs
| filter contains(k8s.pod.name, "bc2-batch", caseSensitive:false)
    or contains(host.name, "bc2-batch", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "bc2-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "bc2-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 2
| fields host, Message
```

### pc2-batch, expect 2

```
fetch logs
| filter contains(k8s.pod.name, "pc2-batch", caseSensitive:false)
    or contains(host.name, "pc2-batch", caseSensitive:false)
    or contains(log.source, "pc2-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "pc2-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "pc2-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 2
| fields host, Message
```

### bc2-ui, expect 2

```
fetch logs
| filter contains(k8s.pod.name, "bc2-ui", caseSensitive:false)
    or contains(host.name, "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-ui", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "bc2-ui", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "bc2-ui", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 2
| fields host, Message
```

### cm2-ui, expect 2

```
fetch logs
| filter contains(k8s.pod.name, "cm2-ui", caseSensitive:false)
    or contains(host.name, "cm2-ui", caseSensitive:false)
    or contains(log.source, "cm2-ui", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "cm2-ui", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "cm2-ui", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 2
| fields host, Message
```

### mailservice, expect 1

```
fetch logs
| filter contains(k8s.pod.name, "mailservice", caseSensitive:false)
    or contains(host.name, "mailservice", caseSensitive:false)
    or contains(log.source, "mailservice", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "mailservice", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "mailservice", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 1
| fields host, Message
```

### BAU-4050, matching lines

Splunk reads index `pc2-batch` and keeps events that contain the exception sentence. A returned row means the sentence was found.

```
fetch logs
| filter contains(k8s.pod.name, "pc2-batch", caseSensitive:false)
    or contains(host.name, "pc2-batch", caseSensitive:false)
    or contains(log.source, "pc2-batch", caseSensitive:false)
| filter contains(content, "Creation of payment request in BC has thrown an exception", caseSensitive:false)
| fieldsAdd src = coalesce(k8s.pod.name, host.name, log.source)
| sort timestamp desc
| fields timestamp, src, content
```

### BillingCenter reimbursement check, matching lines

```
fetch logs
| filter contains(k8s.pod.name, "bc2-ui", caseSensitive:false)
    or contains(host.name, "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-ui", caseSensitive:false)
| filter contains(content, "errcode=E0105errinfo=E010500004", caseSensitive:false)
| fieldsAdd src = coalesce(k8s.pod.name, host.name, log.source)
| sort timestamp desc
| fields timestamp, k8s.pod.name, host.name, src, content
```

0 records on a PODFrozen query means the name count matched. 0 records on BAU-4050 or the reimbursement check means that phrase was not in the window.

## Data flow map

```
PODFrozen
  log line
    → unit = matching pod name, else matching host name
    → Message = countDistinct(unit)
    → Message is the expected number → no row
    → Message is any other number → host Total, Message

Text check
  log line for that index token
    → content contains the phrase
    → one row per matching line
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What each Splunk block checks. |
| `2-result.md` | The DQL to paste. |
| `3-glossary.md` | Terms. |
| `18-splunk-alerts-to-dql-follow.txt` | Same DQL for mobile. |
| `18.sh` | Copy commands. |

Commands: [18.sh](18.sh)
