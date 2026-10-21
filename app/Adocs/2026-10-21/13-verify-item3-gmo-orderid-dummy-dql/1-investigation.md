# Investigation

## Why dummy

Live bc2 logs may be missing or quiet. Dummy rows prove the parse and `count > 1` logic.

## Match your afterBind style

| afterBind verify | #3 verify |
|---|---|
| `fieldsAdd dummy = "Exception…"` | `fieldsAdd content = "…Integration.GMO…&orderid=…"` |
| filter contains on dummy | filter contains on content, then substring cut |
