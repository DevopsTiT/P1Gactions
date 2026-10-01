# Investigation

| Check | Finding |
|---|---|
| Tags in input4.sh | AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP and AGO_DEFAULT_ASSIGNMENT_GROUP:Database_AXAJP |
| v4 group order | The specific Oracle tag is tried first, which is correct |
| v4 behaviour when the SILVA check fails | It dropped the tag group and fell back to other groups, which was wrong |
| Known SILVA sys_id | 5223d8c61b8f3c54688064e4604bcb12 |
