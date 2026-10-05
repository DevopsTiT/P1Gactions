# Investigation

| Checked | Evidence |
|---|---|
| Screenshots in the seq 36 batch | 22 screenshots, 8 Splunk alerts |
| Application Monitoring alerts | URL, URL for MyAXA, function, AG Portal, BancaPotal, Compass, Compass PB |
| Seq 34 coverage | Both Jenkins detectors split by application, so all 7 are covered |
| Seq 36 coverage | Broker detector, threshold 50 per minute |
| Combined file | 289 lines, 1 locals block, 2 resource blocks (3 detectors after for_each) |
| Secrets | None |
