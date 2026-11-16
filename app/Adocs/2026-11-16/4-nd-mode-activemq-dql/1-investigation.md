# Investigation

`head 1 | table ACTIVEMQMODE` returned one cell, value `A`, for host `wpalja307b.prprivmgmt.intraxa`.

The wider search returned 1,486 events from 2026-11-15 09:00 through 2026-11-16 09:45. Host is only that host. Source is only `ND_Mode_DC1`. Opened lines contain `ACTIVEMQMODE="A"`. The field has two values in the window. `head 1` keeps the newest one.
