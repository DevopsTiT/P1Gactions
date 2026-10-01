# Glossary

| Term | What it means | Why you care |
|---|---|---|
| index=aaa | The Splunk index you want to check. | All searches are limited to it. |
| source | File path an event came from. | Your list is compared against it. |
| tstats | Fast search on indexed fields. | Quick even over 30 days. |
| metadata | Lists sources with first and last seen. | All-time check. |
| makeresults | Creates rows without searching data. | Turns your list into rows. |
| mvexpand | Splits one list into many rows. | One row per path. |
| earliest=-30d | Look back 30 days. | Change it if files are quiet. |
