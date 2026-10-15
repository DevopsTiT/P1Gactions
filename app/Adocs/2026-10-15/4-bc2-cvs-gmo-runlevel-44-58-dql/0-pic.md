# BC2 CVS GMO RunLevel Pic

```
index=xxx* → startsWith(src, "xxx")
bare word → matchesPhrase
"quoted" → contains caseSensitive:false
field=value → parse → ==
NOT word → not matchesPhrase
stats + where count > 1 → summarize + filter
garbled or cut off → placeholder
```

```
Pods → OneAgent → Grail → fetch logs → src filter → text filters → sort → rows
```
