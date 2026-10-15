# BC2 GMO EXECTRAN 53 Investigation

| What was checked | Finding |
|---|---|
| Splunk #49 text | `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "Exception during GMO call EXECTRAN"` |
| Splunk #53 text | Exactly the same as #49. |
| Answer 4 | #53 was listed together with #49, not left out. |
