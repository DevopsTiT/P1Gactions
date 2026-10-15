# Why 80 DQL Simple Investigation

| Step | Splunk | DQL |
|---|---|---|
| Get failed IDs | Subsearch plus `rex` | Inner query plus `parse` |
| Hand IDs over | `format` builds OR words | `lookup` keeps a table |
| Find kakakucomauto requests | Outer phrase search | Outer `contains` |
| Match | ID words anywhere in the text | `parse` ID, join on field |
