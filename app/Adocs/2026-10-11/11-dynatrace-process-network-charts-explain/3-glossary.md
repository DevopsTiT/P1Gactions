# Process Network Charts Glossary

| Term | What it means | Why you care |
|---|---|---|
| dt.process.network.load | Network load of a process, shown as requests. | Cells Y, BB, CC. |
| dt.process.network.bytes_rx | Bytes received per second. | Cells Z, AA. |
| dt.process.network.bytes_tx | Bytes sent per second. | Outgoing traffic. |
| Bit | One eighth of a byte. | Network speeds use bits. |
| m1[] | Every point of the series m1. | Used to multiply each point. |
| Process group | All copies of a process. | PROCESS_GROUP- IDs. |
| Process group instance | One running copy. | PROCESS_GROUP_INSTANCE- IDs. |
| instance_of | Link from an instance to its group. | Finds the group of an instance. |
| Bursty | Idle most of the time, busy in short bursts. | Averages hide it. |
