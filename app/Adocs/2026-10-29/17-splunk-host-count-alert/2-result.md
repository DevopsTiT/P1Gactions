# Result

`Message` is the number of hosts that sent at least one event. The search returns a row only when that number is not 4.

```
index="alfrescoacr-batch"
| stats count by host
| fields - count
| appendpipe [|stats count as Message | eval host="Total"]
| where host="Total"
| where NOT Message=4
```

Four hosts produce no statistics row. Three hosts produce `host=Total`, `Message=3`. No events in the window also produce no row, so an empty index and a healthy count of 4 look the same unless you also read the event count.

The agrex search is the same pattern with `NOT Message=1`.
