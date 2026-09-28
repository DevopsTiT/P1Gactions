# Investigation

| What was checked | Finding |
|---|---|
| Abhay's Teams message | He wants L1/L2 groups and business service from a data map keyed by Dynatrace system. The L2 group is passed by default. Example: EIP -> ALJ_EIP_PRD. |
| Seq 16 OPEN YAML | Business service, offering, group and environment were all fixed constants. |
| Seq 19 event analysis | The system name appears in app, dt.cost.product, dt.security.context and entity names. |
| Assigned person | A person must belong to the assignment group, so assigning Shuge KUI to other groups would fail. |
| Offering | A default offering belongs to the default business service, so it must not be paired with a mapped one. |
