# Result

| Need | Use |
|---|---|
| Just see which sources exist | Query 1: one tstats line with OR |
| A yes or no for every source | Query 2: tstats plus your list |
| Rough check on a huge index | Query 3: metadata |

Remember to set the time range wide enough (All time or `earliest=-30d`), or quiet sources will look missing.
