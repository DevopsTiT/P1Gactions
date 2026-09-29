# Result

| Point | Action |
|---|---|
| Understand where a value came from | Read its `from` field in `snow_required` |
| See every SILVA call | Read `lookup.steps` |
| Oracle event not creating tickets | Maintenance tag is true; decide on SKIP_WHEN_MAINTENANCE |
| Wrong business service | Add it to SERVICE_MAP |
| Wrong group | Add it to GROUP_MAP |
| Safe test | DRY_RUN true in tasks 4 and 5 |
