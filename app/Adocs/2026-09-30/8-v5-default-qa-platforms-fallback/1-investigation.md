# Investigation

| Screenshot field | Value |
|---|---|
| Environment | PoC / VoA / Demo |
| Business service | QA Platforms |
| Service Offering (form) | QA Platforms - AXA GROUP OPERATIONS |
| Service Offering (record name) | QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription |
| Offering environment | Production |
| Offer | ToD Web subscription |
| Assignment group | Ops_Middleware_Monitoring_AXAJP |
| Assigned to | Shuge KUI |
| Impact | 4 - Low |
| Urgency | 4 - Low |
| Priority | 4 - Low |

| v4 behaviour | v5 change |
|---|---|
| Default service was Third Party Services Monitoring Application | Now QA Platforms |
| No grouped default | Default set used when both service and group are missing |
| Environment always from tags | Default set forces PoC / VoA / Demo |
| Offering matched by exact name | Now "starts with", because the record name is longer than the form text |
