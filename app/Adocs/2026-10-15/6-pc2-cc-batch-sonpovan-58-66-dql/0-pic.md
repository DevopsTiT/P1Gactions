# PC2 CC Batch Sonpovan Pic

```
text search → startsWith + contains or matchesPhrase
rex loglevel + search ERROR → parse + filter == "ERROR"
rex failed + search true → contains "failed=true"
rex max_match=0 → splitString + expand + parse + collectArray
substr(401,17) → substring(from:400, to:417)
garbled or cut off → placeholder
```

```
pods → OneAgent → Grail → src filter → parse → filter → summarize or sort → rows
```
