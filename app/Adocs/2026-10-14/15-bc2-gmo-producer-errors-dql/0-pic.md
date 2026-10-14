# BC2 GMO And Producer Errors Pic

## Decision tree

```
#45–#49, #53 → repeats → answer 14
#50 → errcode == E01 → drop 3 codes
#51, #52, #55 → phrase search
#54 → Operation failed + Producer (Japanese unreadable)
```

## Data flow

```
logs -> src prefix -> phrase or field filter -> list
```
