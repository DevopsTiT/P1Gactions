# Investigation

| What was checked | Evidence |
|---|---|
| Screenshot | User's curl file uses `-u 'Tech_DynatraceJP_WS:<real password>'`, `/api/now/v2/table/`, `-H 'Accept: application/json'`, and `jq` |
| Password | Same value already used in the workflow YAMLs |
| Quoting | Password has `^ * ( { } + =`; single quotes keep the shell from changing it |
| Queries | Same V1 to V5 as seq 11, plus V6 from seq 10 |
