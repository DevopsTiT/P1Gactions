# Investigation

| Checked | Finding |
|---|---|
| Group tag rule (line 196) | `AGO_AXA_SUPPORTGROUP` matches test 1 exactly. |
| Environment rules (lines 203 to 218) | `AGO_AXAENVIRONMENTNAME` is test 1, so Development wins over `env:ACC`. |
| Host search (lines 411 to 423) | `host:ts12` with domain `hk.intraxa` from `AGO_DOMAIN` finds ts12.hk.intraxa. |
| CI names (lines 257 to 259) | PROCESS_GROUP_INSTANCE id is filtered out. |
| PD severity (line 890) | Infrastructure gives `error`. |
| PD component (line 892) | Trigram ATK used. |
| Not visible in screenshot | event.name, root cause name, affected names, security context, maintenance field. |
