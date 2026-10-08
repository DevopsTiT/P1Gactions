# Glossary

| Term | What it means | Why you care |
|---|---|---|
| EIP | Enterprise integration platform that talks to MQ | Timeouts mean messages may not flow |
| IBM MQ | Message queue software | The source of the connection timeout logs |
| Queue manager (MQSRVPROD) | The MQ server process that owns queues | Its error log is AMQERR01.LOG |
| AMQERR01.LOG | MQ's current error log file | Where "Connection timed out" appears |
| AGPO | Agency portal application | The AGPO auth service syncs passwords to Auth0 |
| Auth0 | Identity service that stores logins | Password change errors mean users cannot update passwords |
| BadRequest response | Auth0 rejected the request as invalid | One of the two tracked errors |
| NotFound response | Auth0 could not find the user | The other tracked error |
| Throttle | Splunk setting to suppress repeat alerts | 5 seconds does nothing on a 5-minute schedule |
| `matchesValue` | DQL match with `*` wildcard, case-insensitive | Matches WPALJA21B7 with `wpalja21b*` |
