# Process Network Charts

## Decision tree

```
Chart cell result?
 Requests chart, one instance, 3 days         → spiky on top of a steady base (cell Y)
 Bytes received with m1[]*8                   → bytes turned into bits; label "Bytes received" is wrong (cell Z)
     three sharp spikes in 2 hours            → short bursts of incoming data
 Filter on process group, split by instance  → 2 records = 2 instances of the group (cell AA) — correct pattern
 0 records                                    → cell BB: an INSTANCE ID on the GROUP field
     PROCESS_GROUP- ID                        → dt.entity.process_group
     PROCESS_GROUP_INSTANCE- ID               → dt.entity.process_group_instance
 Mostly zero with tall bursts                 → bursty or batch-like process (cell CC)
```

## Short takeaway

| Cell | What it shows | Result | Main point |
|---|---|---|---|
| Y | Network load of one process over about 3 days | 1 series | Steady base with frequent spikes |
| Z | Incoming traffic of one process over 2 hours | 1 series | Values are multiplied by 8, so they are bits, not bytes |
| AA | Incoming traffic of every instance in one group | 2 series | The right way to see all copies of a process |
| BB | Network load by group with an instance ID | 0 records | Same mix-up as answer 2, the other way round |
| CC | Network load of a quiet process | 1 series | Idle most of the time, then bursts |

## Summary

These charts come from Dynatrace process pages ("Network requests" and "Incoming traffic") opened in a notebook. They work when the ID type matches the field. Cell BB fails because an instance ID was put in the process group filter. Cell Z is correct but its label says bytes while the numbers are bits.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| `dt.process.network.load` | A network load measure of the process, shown on the process page as requests. | Cells Y, BB and CC. |
| `dt.process.network.bytes_rx` | Bytes the process received per second. | Cells Z and AA. |
| `bytes_tx` | Bytes the process sent. | The other direction. |
| Bit and byte | 1 byte = 8 bits. Network speeds are usually shown in bits per second. | Explains the `*8`. |
| `m1[]` | Means "every point in the series m1". | `m1[]*8` multiplies every point. |
| Process group | All copies of the same process. ID starts with `PROCESS_GROUP-`. | Field `dt.entity.process_group`. |
| Process group instance | One running copy. ID starts with `PROCESS_GROUP_INSTANCE-`. | Field `dt.entity.process_group_instance`. |

### Cell Y: requests of one process, about 3 days

```
//queryId=ProcessPerformanceNetworkRequests
timeseries avg(dt.process.network.load), by:{dt.entity.process_group_instance},
  filter: dt.entity.process_group_instance == "PROCESS_GROUP_INSTANCE-8C3BEE6BA667352E"
| fieldsAdd metricName = "Requests"
```

The ID is read from the photo and may have a character wrong.

| Result | Meaning |
|---|---|
| Timeframe 6/28 17:30 to 7/1 18:00 | About three days |
| A steady base line | Constant background traffic |
| Frequent spikes, a few about double the base | Bursts during the day; the tallest ones are worth matching to batch times |
| Busier stretch on the last day | Higher activity near 7/1 |

The top of this screenshot also shows the end of the June chart from answer 10: one wave per day.

### Cell Z: incoming traffic of one process, 2 hours

```
//queryId=PerformanceAnalyticsProcessesNetworkIncomingTraffic
timeseries m1 = avg(dt.process.network.bytes_rx), by:{dt.entity.process_group_instance},
  filter: dt.entity.process_group_instance == "PROCESS_GROUP_INSTANCE-38F231AB4892E434"
| fieldsAdd m1 = m1[]*8
| fieldsAdd metricName = "Bytes received"
```

| Line | What it does |
|---|---|
| `avg(dt.process.network.bytes_rx)` | Bytes received per second |
| `m1 = m1[]*8` | Multiplies every point by 8, turning bytes into bits |
| `metricName = "Bytes received"` | A legend label, copied from the Dynatrace page |

| Result | Meaning |
|---|---|
| About 16:19 to 18:20 | Two hours |
| Low base, well under 200 kbit/s | Quiet most of the time |
| Three spikes: about 800 kbit/s, about 1.2 Mbit/s, and a smaller one | Short bursts of data arriving, for example a file or a big response |
| Same process as answer 10, cell X | This is the incoming traffic of that process |

Label problem: after `*8` the values are bits per second, but the label still says "Bytes received". Read the axis as bits.

### Cell AA: all instances of one process group

```
timeseries m1 = avg(dt.process.network.bytes_rx), by:{dt.entity.process_group_instance},
  filter: dt.entity.process_group == "PROCESS_GROUP-A73B79EBAEDBF111"
| fieldsAdd m1 = m1[]*8 | fieldsAdd metricName = "Bytes received"
```

| Point | Explanation |
|---|---|
| Filter on the group, split by instance | The correct pattern for "show every copy of this process" |
| 2 records | This group has two running instances |
| Same group as answer 2, cell 1 | The process group whose network load was charted there |
| Lines look flat | Low traffic over 6/24 to 7/1, or the scale is stretched by one tall point |

### Cell BB: 0 records

```
timeseries avg(dt.process.network.load), by:{dt.entity.process_group},
  filter: dt.entity.process_group == "PROCESS_GROUP_INSTANCE-B2059778413E0B79"
```

| What the filter expects | What was given |
|---|---|
| A group ID, `PROCESS_GROUP-...` | An instance ID, `PROCESS_GROUP_INSTANCE-...` |

This is the opposite of answer 2, cell 2. Either filter `dt.entity.process_group_instance` with this ID, or look up the group of this instance first (query BB2).

### Cell CC: a bursty process

```
//queryId=ProcessPerformanceNetworkRequests
timeseries avg(dt.process.network.load), by:{dt.entity.process_group_instance},
  filter: dt.entity.process_group_instance == "PROCESS_GROUP_INSTANCE-3A9B81C22D673E16"
| fieldsAdd metricName = "Requests"
```

| Result | Meaning |
|---|---|
| Short window, about 40 minutes | Zoomed in |
| Mostly at zero | The process is idle most of the time |
| Separate tall bursts, one much higher | Work comes in batches or on a schedule |
| Gaps in the line | Minutes with no data at all |

For a process like this, an average hides the pattern. Count busy minutes and look at the peak instead (query CC1).

## Result

| Cell | Verdict | Fix or use |
|---|---|---|
| Y | Works | Match the tallest spikes to batch times |
| Z | Works, wrong label | Call it bits received per second |
| AA | Works, correct pattern | Add the instance name |
| BB | ID type mismatch | Use the instance field, or find the group first |
| CC | Works | Use peak and busy minutes, not the average |

Rule to remember:

| ID starts with | Filter field |
|---|---|
| `PROCESS_GROUP-` | `dt.entity.process_group` |
| `PROCESS_GROUP_INSTANCE-` | `dt.entity.process_group_instance` |
| `HOST-` | `dt.entity.host` |
| `SERVICE-` | `dt.entity.service` |

## Data flow map

```
OneAgent on the host
  → process network metrics
      dt.process.network.load      → "Requests" charts (cells Y, BB, CC)
      dt.process.network.bytes_rx  → "Incoming traffic" charts (cells Z, AA), × 8 for bits
  → filter by ID
      PROCESS_GROUP_INSTANCE- on instance field → one process (Y, Z, CC)
      PROCESS_GROUP- on group field, split by instance → every copy (AA)
      INSTANCE ID on group field → 0 records (BB)
```

## Related files

| File | What it is |
|---|---|
| `11-dynatrace-process-network-charts-explain-improved.dql` | Fixed BB, honest labels, in and out traffic, burst check |
| `10-dynatrace-activegate-entity-network-load-explain/` | The June chart for the same process |
| `2-dynatrace-notebook-queries-explain/` | The first ID mix-up |
| `3-glossary.md` | Terms |
| `11.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. `11.sh` has only git lines. Nothing has been run.
