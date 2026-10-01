# Icontains Check Picture

```
pic1 table (log.source per host group)
 ├─ QA icontains full pic2 path?  → true  → pic2 file is ingested
 │                                 → false → QC
 ├─ QB each pic2 path             → FOUND / MISSING
 └─ QC icontains file name only   → match  → similar file, different OS path
                                   → none   → pic2 files live in another host group
```

```
fetch logs → filter host group → summarize by log.source
  → pic2 = array(23 paths)
  → iAny(contains(log.source, pic2[], caseSensitive: false))
  → iCollectArray(...) = which paths matched
```
