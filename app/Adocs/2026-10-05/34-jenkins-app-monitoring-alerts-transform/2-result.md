# Jenkins App Monitoring Result

| Detector | Replaces | Window |
|---|---|---|
| `Prod_Jenkins_AppMonitoring_URLCheckFailed_High` | URL, URL for MyAXA | 15 minutes |
| `Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High` | function and the 7 per-app function alerts | 120 minutes |

| Ask | Why |
|---|---|
| Macro definitions | Maintenance and state logic |
| Configuration lookup CSV | application and pager_duty per job |
| Standard flow rule on `pagerduty.enabled` | Keep email-only apps from paging |
| Routing fallback on `app.name` | No host tags on these problems |
