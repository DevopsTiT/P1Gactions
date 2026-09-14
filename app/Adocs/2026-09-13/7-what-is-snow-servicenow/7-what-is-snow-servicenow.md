# What SNOW Means

```
See __SNOW_INSTANCE_URL__?
  → SNOW = ServiceNow
  → Replace with your ServiceNow website URL
```

| Key point | Detail |
| --- | --- |
| SNOW | Short name for **ServiceNow** |
| `__SNOW_INSTANCE_URL__` | Your ServiceNow base URL |
| Example | `https://yourcompany.service-now.com` |

## Summary

In our workflow files, **SNOW** means **ServiceNow** (the ticket / ITSM system). Any placeholder starting with `__SNOW_...__` is a ServiceNow setting you must fill in.

## Common placeholders

| Placeholder | Meaning |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | ServiceNow site URL |
| `__SNOW_USER__` | Integration username |
| `__SNOW_PASSWORD__` | Integration password |
| `__SNOW_CALLER_SYS_ID__` | Caller user id in ServiceNow |
| `__SNOW_GROUP_SYS_ID_*__` | Assignment group ids |

## Related

Seq 4 workflow files use these placeholders; seq 5 explains setup.
