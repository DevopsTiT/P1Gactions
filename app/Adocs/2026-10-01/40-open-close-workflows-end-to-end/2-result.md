# Result

| Point | Detail |
|---|---|
| OPEN | Creates one SILVA INC and one PD alert per new problem, after previews pass. |
| CLOSE | Resolves the same INC and PD alert when the problem closes. |
| Link | correlation_id and dedup_key, both from the problem display id. |
| Keep active | OPEN (seq 36) plus one CLOSE (seq 37 or 39). |
| Before go-live | Confirm close_code (`40.sh` line 2), Save / Deploy both. |
