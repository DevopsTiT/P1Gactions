# Any App Filter Not Only Three

```
app:eip / app:api / app:payment
  → examples only (not a fixed list of 3)

Any monitored app
  → same board + filter by that app’s tag (or MZ)
```

| Key point | Detail |
| --- | --- |
| Fixed to 3 apps? | **No** |
| What to do | Tag every monitored app the same way: `app:<name>` |
| How to select | Dashboard filter on tag key `app` → pick **any** value that exists |
| Board count | Still **one** main board |

## Summary

EIP / API / Payment were sample names. Any app OneAgent (or OTel) monitors can appear on the same Generic V2–style board once it has an `app:` tag. Selecting that tag filters all tiles to that app.

## Rule

| Item | Practice |
| --- | --- |
| Tag key | Always `app` |
| Tag value | Real app id/name you use in Dynatrace (any string) |
| Examples | `app:eip`, `app:api`, `app:payment`, `app:claims`, `app:portal`, … |
| New app | Add tag on its hosts + services → it shows up in the filter list |
| No tag | App data may still show under **All** (empty filter), but cannot be selected cleanly alone |

## How to select any app (Classic)

1. Keep one board: **Main-All-Apps-Status (Generic V2 style)**
2. Leave filter empty → **all** monitored apps
3. Dashboard filter → Tag → key `app` → choose **any** value present in the tenant
4. Clear filter → back to all

You do **not** need a CSV limited to three names. Classic dashboard filter lists tag values that exist on entities.

## Optional: Management Zone instead of tag

| Approach | When |
| --- | --- |
| Tag `app:<name>` | Best default; one board, pick any app |
| Management Zone per app | If your org already uses MZs; filter board by MZ |
| Entity name contains | Weak fallback if tags are missing |

## Do / Don’t

| Do | Don’t |
| --- | --- |
| Tag every monitored app `app:<its-name>` | Hard-code only eip/api/payment forever |
| One board + pick any `app` value | One dashboard file per app |
| Use **All** (no filter) for estate view | Assume only three apps exist |

## Related

Board JSON: `../14-main-all-apps-status/Main-All-Apps-Status-Classic.json`  
Same metrics for every app; selection is by tag, not by changing metrics.
