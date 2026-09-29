# Investigation

| Evidence | Finding |
|---|---|
| query.sh `assignment_group.nameLIKEDatabase_AXAJP` | Works. Returns several services, all with group sys_id 5223d8c61b8f3c54688064e4604bcb12 |
| Service names returned | Contain environment words such as Production, Integration / Test, Non-Prod |
| First curl in the terminal | Failed with "URL rejected: Malformed input" because of unencoded characters |
| v4 before this change | Jumped from scored search straight to the static default service |
