# Investigation

## Built from

| Source | Used for |
|---|---|
| match-examples part 1–3 | Dummy `content` / host / pod |
| line-by-line part 1–3 | Pipeline after `fetch logs` |
| Alias map | Repeats (#12, #44–49, #53, #56) |

## Why `data record` not `fetch` + dummy field

Host/pod/`log.source` filters need those fields present. `data record` sets them. Phrase-only checks can still use your `fieldsAdd dummy` style.
