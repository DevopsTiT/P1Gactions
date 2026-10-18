# Control-M Data Flow Pic

```
A logs:     Agent file / alert → OneAgent/shipper → Grail → DQL detector → Problem → workflow
B API:      ActiveGate → login/API key → GET /run/jobs/status → controlm.* metrics → event → Problem
C process:  EM/Server JVM + javaagent → OneAgent → process health
DQL never calls Automation API. Extension does. Your abend/overrun = path A only.
```
