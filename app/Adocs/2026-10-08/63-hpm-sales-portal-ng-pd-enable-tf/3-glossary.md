# HPM Sales Portal NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| HPM_Sales_Portal | Application name in configuration | Selects the Sales Portal jobs |
| build_report | event_tag on each finished jenkins/test build | First filter |
| App-Ops Functional job | Detailed test job | Not counted for OK/NG |
| applications/* job | Plain per-app check | Counted |
| pagerduty.enabled | Flag the workflow reads | "0" until actions are confirmed |
