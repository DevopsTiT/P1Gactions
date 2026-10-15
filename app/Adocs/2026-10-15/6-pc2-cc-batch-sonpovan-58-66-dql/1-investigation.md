# PC2 CC Batch Sonpovan Investigation

| What was checked | Finding |
|---|---|
| #58 text | The Japanese characters are garbled in the screenshot. |
| #61 and #62 regex | Both read the log level after a `yyyy-MM-dd HH:mm:ss,SSS` timestamp. |
| #62 exclusion | `log != "*Sonpovan <Japanese>*"`, where the Japanese part is garbled. |
| #62 details | `max_match=0` with `[0-9]{10}\s.*` collects lines that start with a 10-digit ID. |
| #63 and #64 | Same shape. Only the work item name differs. |
| #65 class name | Partly unreadable. Best reading is `VanTRecvAccountStatementCallApiTasklet`. |
| #66 | Cut off at the bottom of the screen. |
