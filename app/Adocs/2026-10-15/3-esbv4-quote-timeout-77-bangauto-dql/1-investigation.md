# ESBv4 Quote Timeout 77 Investigation

| What was checked | Finding |
|---|---|
| Splunk #77 structure | It is identical to #78 except for the channel path. |
| Channel path | `/esb/ebroker/bangauto/online/_quote` |
| Error text | `.../pc/service/edge/ebroker/quote' failed: Timeout exceeded.` |
| ID regex | A UUID of 8-4-4-4-12 lowercase hex characters. |
| DQL pattern reused | The same pattern as today's answer 1 (#78 to #80). |
