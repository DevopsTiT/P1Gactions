# Investigation

| What I checked | Finding |
|---|---|
| Screenshot | Paths under /app, /IFDATA, /opt/HULFT, /opt/plat, /var/opt/universal. First line is cut off. |
| Case | `HUL_JOB.LOG` is upper case; search 1 compares in lower case. |
| No extension | `/opt/HULFT/etc/trace` needs its own monitor stanza if inputs use `*.log`. |
| Method | `source` is an indexed field, so `tstats` and `metadata` answer quickly. |
