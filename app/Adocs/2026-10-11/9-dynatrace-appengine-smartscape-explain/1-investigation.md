# AppEngine Usage And Smartscape Nodes Investigation

| Cell | Evidence on screen |
|---|---|
| Q | fetch dt.system.events with scanLimitGBytes -1, AppEngine Functions - Small, two summarize steps |
| R | Same source, grouped by user.email and caller.app.id, 0 records over 4/8 to 5/8 |
| S | CoPilot message: could not generate a valid DQL query |
| T | smartscapeNodes("ACTIVE_GATE"), 0 records |
| U | 8 types: CONTAINER 1,089, DISK 7,543, FRONTEND 14, HOST 2,327, NETWORK_INTERFACE 3,138, ONEAGENT 2,327, PROCESS 35,280, SERVICE 1,942 |
