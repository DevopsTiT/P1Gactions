# Investigation

| What was checked | What it showed |
|---|---|
| User request | The default environment should be Development. |
| Seq 13 OPEN | FIXED_ENVIRONMENT and DEFAULT_ENVIRONMENT were Production. The offering was the Production record. |
| Seq 13 screenshot of the offering | The Name holds the environment: "... - Production - ToD Web subscription". |
| Seq 13 CLOSE | Does not send the environment, so no change is needed. |
| ENVIRONMENT map in OPEN | Already includes "Development" as a label. |
