# Result

Start with the error-log query. Add contains when you know a service name. Use summarize when the list is too long. Use problems for what is still open, and spans for slowness.

| Need | First command |
|---|---|
| Error lines | fetch logs |
| A name in the message | fetch logs |
| A ranking | fetch logs, then summarize |
| An open problem | fetch dt.davis.problems |
| A slow call | fetch spans |
