# Glossary

| Term | What it means | Why you care |
|---|---|---|
| index | Named storage area in Splunk. | You check sources inside one index. |
| source | File path or input name of an event. | Your list is a list of sources. |
| sourcetype | Data format label. | Shown in search 2. |
| host | Server that sent the event. | One path can come from many hosts. |
| tstats | Fast search on indexed fields. | Checks existence quickly. |
| metadata | Command listing sources with first and last seen times. | All-time view. |
| makeresults | Creates rows from nothing. | Turns your list into rows. |
| mvexpand | Splits a multi-value field into rows. | One row per path. |
| Universal Forwarder | Agent that reads files and sends them. | Must be watching the file. |
| inputs.conf | Forwarder file listing monitored paths and target index. | Wrong or missing stanza is the usual cause. |
| btool | Splunk tool showing the merged config and which file set it. | Proves what the forwarder is configured to read. |
| _internal | Splunk's own log index. | Shows forwarder reading errors. |
