# Portals AMP Check Query Pic

## Line tree

```
1 fetch 24h logs
2-5 keep if host / pod / container / source contains "portals-amp"
6 group by 5 fields, count
0 rows → not in Dynatrace
```

## Data flow

```
logs -> name filter -> group -> count -> 0 rows
```
