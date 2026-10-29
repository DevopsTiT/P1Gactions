# Investigation

| Source | Finding |
|---|---|
| Index | `alfrescoacr-batch`. |
| Host step | `stats count by host`, then `fields - count`. |
| Total row | `appendpipe` sets `host` to `Total` and `Message` to the number of host rows. |
| Keep rule | `where host="Total"` then `where NOT Message=4`. |
| Events | 176,642. Window 10/28/2026 1:00:00 PM to 10/29/2026 1:43:12 PM. |
| Statistics | 0, so the host count in that window is 4. |
