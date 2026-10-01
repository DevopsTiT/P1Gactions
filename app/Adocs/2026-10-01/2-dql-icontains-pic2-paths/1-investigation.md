# Investigation

| What was checked | Evidence |
|---|---|
| Pic1 query | `fetch logs`, host group `HOST_GROUP-D4032DA3E0240421`, `summarize count(), by:log.source`, 27 records |
| Pic1 sources | Windows paths on `C:\` and `D:\`, plus "Windows Application Log" |
| Pic2 list | 23 Linux paths, editor lines 462–484 |
| Wildcard lines | 3 lines contain `*`; the text before `*` is used for contains |
| Visible overlap | No full path overlap. File-name overlap likely only for HULFT `trace` |

| Design choice | Reason |
|---|---|
| Summarize before contains | 27 rows instead of millions of lines |
| `caseSensitive: false` | Matches "icontains" (case-insensitive contains) |
| Iterative functions `iAny` and `iCollectArray` | Check all 23 paths in one expression and report which matched |
