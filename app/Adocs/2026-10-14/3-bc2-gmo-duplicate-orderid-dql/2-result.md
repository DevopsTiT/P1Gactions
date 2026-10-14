# BC2 GMO Duplicate OrderID DQL Result

| Item | Value |
|---|---|
| Host filter | host.name or k8s.pod.name starts with bc2- |
| orderid | substring between &orderid= and next & |
| Pattern | first 18 chars + "*" + chars from 24 |
| Output | OrderIDPattern, count, orderids, count > 1 |

## If empty

| Check | Result | Meaning |
|---|---|---|
| Check 1 | 0 | Logs not in Dynatrace. |
| Check 2 | Odd orderid | Adjust the indexOf text. |
| Main | 0 with good checks | No duplicates. |
