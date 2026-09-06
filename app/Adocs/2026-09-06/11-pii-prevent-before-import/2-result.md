# Result

Install the blocklist as **standing gates** now. You do not need existing PII volume to create rules.

| Do now | Done when |
| --- | --- |
| App logger deny-list from `pii-keys-blocklist.txt` | Forbidden keys never emitted |
| OneAgent masking (top 20 → full wave) | Fake JSON shows `***` |
| OpenPipeline fieldsRemove + content mask | Same fake line safe at ingest |
| Fake-only proof test | DQL shows no raw values |
| Enable real log import after gates | Weekly `pii-scan.dql` stays clean |

Do **not** wait for “important” logs before configuring Dynatrace masking.
