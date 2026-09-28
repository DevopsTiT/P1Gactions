# Enrich Only Reading Map

## Decision tree

```
Blank field on the SILVA ticket?
 Environment / Business service / Category / Subcategory / Assignment group
    → now sent by OPEN post-silva-incident-http
 Still blank after import?
    → read notFilled in the task result
    → label does not match SILVA → fix label in prepare-payload settings
 Notes missing?
    → comments field name or ACL on SILVA
```

## Data flow

```
Problem ACTIVE → prepare-payload (event + Problems API → fields + customer notes)
                   ├─► post-silva-incident-http (all fields + comments)  ┐ same time
                   └─► trigger-pagerduty (same details)                  ┘
Problem CLOSED → prepare-close-ids (duration, cause, notes)
                   ├─► resolve-silva-incident-http (state 6 + close_notes + comments) ┐ same time
                   └─► resolve-pagerduty (unchanged)                                  ┘
```
