# Top Dynatrace Commands

```
What do you need in a Notebook?
  the newest log lines → command 1
  one log file → command 2
  a phrase in the line → command 3
  how many lines each host sent → command 4
  the HOST_GROUP- id for a hostname → command 5
  every host in that group → command 6
  how many different hosts or pods → command 7
  problems still open → command 8
  whether a host is busy → command 9
  a slow request → command 10
```

| Command | What you get |
|---|---|
| 1. Newest logs | The latest 20 log lines. |
| 2. One log file | Lines from one path. |
| 3. A phrase | Lines whose text contains the word you type. |
| 4. Lines per host | A count of log lines for each host. |
| 5. Host group id | The `HOST_GROUP-` value for a hostname. |
| 6. Group members | Every host in that group. |
| 7. Distinct names | How many different hosts or pods matched. |
| 8. Open problems | Problems that are still active. |
| 9. Host CPU | CPU over time for each host. |
| 10. Slow spans | The slowest request spans. |

## Summary

These are Dynatrace Query Language commands. Paste one into a Notebook. Set the time picker to Last 2 hours, then widen it if the result is empty. Leave `from:` out of the query so the picker controls the window.

## Investigation

| Source | What it contributed |
|---|---|
| Notebooks used for the log path and the host group | Commands 2, 5, and 6. |
| The host-count alert | Command 7. `count()` counts lines. `countDistinct()` counts names. |
| Dynatrace built-in records | Commands 1, 3, 4, 8, 9, and 10. |

## Result

Replace the quoted word in commands 2, 3, 5, and 7 with the name you are checking. Every `contains` below is case insensitive.

### 1. Newest logs

Use this when you want to see what arrived.

```
fetch logs
| sort timestamp desc
| limit 20
```

### 2. One log file

Use this when you know the file path.

```
fetch logs
| filter contains(log.source, "default.log", caseSensitive:false)
| sort timestamp desc
| limit 20
```

### 3. A phrase in the line

Use this when you know a word in the message, such as `FAILURE`.

```
fetch logs
| filter contains(content, "FAILURE", caseSensitive:false)
| sort timestamp desc
| limit 20
```

### 4. Lines per host

Use this to see which hosts sent the most lines. This number is a line count.

```
fetch logs
| summarize lines = count(), by: { host.name }
| sort lines desc
```

### 5. Host group id from a hostname

Use this to copy the Terraform `scope`. Change the hostname.

```
fetch dt.entity.host
| filter contains(entity.name, "CEAA20F7", caseSensitive:false)
| fieldsAdd host_group_id = instance_of[dt.entity.host_group]
| fieldsAdd host_group_name = entityName(instance_of[dt.entity.host_group])
| fields entity.name, id, host_group_id, host_group_name
```

`host_group_id` starts with `HOST_GROUP-`. That is the scope. `id` starts with `HOST-`. That is the host itself.

### 6. Hosts in one group

Paste the id from command 5.

```
fetch dt.entity.host
| filter dt.entity.host_group == "HOST_GROUP-9034BF4FC7D158B2"
| fields entity.name, id
| sort entity.name asc
```

### 7. How many different hosts or pods

Use this when an alert should count machines, and a line count would be the wrong number. Replace `TOKEN` in all five places.

```
fetch logs
| filter contains(k8s.pod.name, "TOKEN", caseSensitive:false)
    or contains(host.name, "TOKEN", caseSensitive:false)
    or contains(log.source, "TOKEN", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "TOKEN", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "TOKEN", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
```

`Message` is the number of different names. Add this line at the end when the alert should stay empty while the count is 4:

```
| filter Message != 4
```

### 8. Problems still open

Use this to see what is still active.

```
fetch dt.davis.problems
| filter event.status == "ACTIVE"
| fields timestamp, display_id, event.name, event.status
| sort timestamp desc
| limit 20
```

### 9. Host CPU

Use this to see which hosts are busy. The picker sets the time window.

```
timeseries avg(dt.host.cpu.usage), by: { dt.entity.host }
| limit 10
```

### 10. Slow request spans

`duration` is in nanoseconds. 1,000,000,000 nanoseconds is one second.

```
fetch spans
| filter duration > 1000000000
| fields timestamp, span.name, duration
| sort duration desc
| limit 20
```

## Data flow map

```
Notebook time picker
        |
        v
paste one command
        |
        +--> logs        commands 1, 2, 3, 4, 7
        +--> hosts       commands 5, 6, 9
        +--> problems    command 8
        +--> spans       command 10
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which command answers which question. |
| `1-investigation.md` | Where each command comes from. |
| `2-result.md` | The ten commands in short form. |
| `3-glossary.md` | The words in the commands. |
| `4-top-dynatrace-dql-commands-follow.txt` | The same commands for a phone. |
| `4.sh` | Copy commands. |

Commands: [4.sh](4.sh)
