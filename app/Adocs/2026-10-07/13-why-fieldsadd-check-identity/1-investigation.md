# Why FieldsAdd Check Investigation

| What was checked | Finding |
|---|---|
| Records analyzer | Every returned row counts as a violation. |
| Grouping | `alertIdentityFields` decides which rows belong to the same problem. |
| Batch lines | 8 different texts per night |
| Host name | Case changes between nights, so it is not stable |
