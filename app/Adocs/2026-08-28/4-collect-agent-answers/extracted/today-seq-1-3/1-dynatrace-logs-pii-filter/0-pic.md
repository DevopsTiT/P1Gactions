# 0 Pic Overview

```
Need PII out of Dynatrace logs?
  can stop in app logger? → YES → fix app first (strongest)
  OneAgent collecting? → Sensitive data masking at capture
  Fluent Bit / OTel / API? → mask in shipper OR OpenPipeline at ingest
  need one policy for all channels? → OpenPipeline → Grail
  PII already in Grail? → Sensitive Data Center cleanup + tighten ingest
  analyst must not SEE PII? → DQL mask at query (display only, not delete)
```

```
OpenPipeline processor
  whole line toxic → Drop record
  one secret field → Remove fields
  pattern in content → DQL replacePattern / parse
  structured JSON → fieldsRemove or DQL on attribute
```

```
App logger → OneAgent capture mask → OpenPipeline ingest → Grail
                                              ↑
                                    DQL query mask (UI only)
```
