# Dynatrace Control-M Overview

## Decision tree

```
What do you need from Dynatrace + Control-M?
 Job ended not OK (abend)?
   → log detector on Control-M alert / agent lines (see 2026-10-12 seq 39)
 Job still running too long (overrun)?
   → pair STARTED + ENDED in daily_ctmag log (see 2026-10-12 seq 40, 41)
 Live job status counts without parsing logs?
   → Hub extension "Control-M Jobs v2" (Automation API → ActiveGate)
 Watch Control-M EM / Server / Agent as Java processes?
   → OneAgent / javaagent on those hosts (BMC APM guide)
 After Dynatrace upgrade EM crashes?
   → avoid OneAgent 1.327 on Control-M/EM Linux until BMC fix (CTM-13123)
 Logs not found in Grail?
   → filter log.source contains "daily_ctmag_" or controlm alert source
   → confirm agent hosts still ship logs
```

## Short takeaway

| Question | Answer |
|---|---|
| What is Control-M? | BMC's job scheduler. It starts, waits on, and ends batch jobs across servers. |
| What does Dynatrace add? | Sees job health (fail, hang, status) and the hosts that run Control-M. |
| How you monitor it today | Agent daily log `daily_ctmag_*.log` in Grail, plus DQL detectors. |
| Official product path | Dynatrace Hub extension **Control-M Jobs v2** (polls Automation API). |
| Biggest trap | OneAgent 1.327 can crash Control-M/EM on Linux. Do not upgrade EM hosts to that build until BMC says it is safe. |

## Summary

Control-M runs the batch schedule. Dynatrace watches whether those jobs fail, hang, or stay healthy. Your shop already does the log path (abend and overrun detectors). Dynatrace also sells a remote extension that reads status from the Control-M Automation API. Keep those two paths clear: logs answer "what happened in the agent log," the extension answers "what does Control-M say the job state is right now."

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Control-M | BMC product that schedules and runs jobs. | Source of batch work you must watch. |
| Control-M/EM | Enterprise Manager. The control plane UI and services. | Where operators manage the schedule. Fragile with bad OneAgent versions. |
| Control-M Agent | Process on a host that actually starts OS jobs. | Writes `daily_ctmag_YYYYMMDD.log`. |
| ORDERID | Id for one ordered run of a job. | Ties STARTED to ENDED. |
| RUNNO | Run number for that order. | Reruns are separate. |
| Ended Not OK | Control-M's name for a failed / abend end. | Classic page-worthy failure. |
| AJF | Active Job File. Jobs Control-M currently tracks. | Extension metric "not in AJF" means the job was not found there. |
| Automation API | HTTP API on Control-M for job status and control. | What the Hub extension calls. |
| ActiveGate | Dynatrace gateway that can run remote extensions. | Extension runs here, not on every agent. |

### Two ways Dynatrace watches Control-M

| Path | How it works | Best for | Your existing work |
|---|---|---|---|
| Log path | OneAgent or log shipper sends agent / alert logs to Grail. DQL detectors parse STARTED, ENDED, "Ended not OK". | Overrun, abend text, custom job lists, Splunk-parity alerts. | Seq 39 abend, seq 40/41 overrun. |
| Extension path | ActiveGate calls Control-M Automation API. Metrics such as `controlm.job.status` and job counters. | Live status, wait counts, API connectivity, optional error events. | Hub add-on if you enable it. |
| Process path | OneAgent / javaagent on EM, Server, Agent, Automation API Java. | CPU, GC, crashes of Control-M itself. | Host monitoring. |

### Log path (what you already use)

```
Control-M Agent
  → /opt/ctmhlx/ctm/dailylog/daily_ctmag_YYYYMMDD.log
  → Grail (log.source contains daily_ctmag_)
  → DQL detector
       STARTED vs ENDED → overrun
       Ended not OK / ENDED NOTOK → abend
  → Davis problem → workflow / email / PagerDuty
```

| Splunk habit | Dynatrace form |
|---|---|
| `index="controlm*"` | `contains(log.source, "daily_ctmag_", caseSensitive:false)` |
| `sourcetype=controlm_agent_log` | Same log source filter, or host list if needed |
| `inputlookup claims_jobs` | `array("JOB1", "JOB2")` then `filter in(job_name, ...)` |
| Start / end fields | Parse `) STARTED (` and `ENDED` lines, group by job_name, order_id, run_no |

### Extension path (Control-M Jobs v2)

Official docs: [Control-M Jobs v2 extension](https://docs.dynatrace.com/docs/observe/infrastructure-observability/extensions/control-m-jobs-v2)

| Need | Detail |
|---|---|
| Dynatrace | 1.309 or newer |
| ActiveGate | 1.289 or newer, Extensions module on |
| Control-M | Automation API enabled, user with API access |
| Config | API URL, username, password, optional server / folder / job name filters |
| Optional | Send error events when a job is Ended Not OK |

| Metric | What it means |
|---|---|
| `controlm.connectivity` | 100 = API reachable, 0 = not |
| `controlm.job.status` | 100 ended OK, 50 executing, 25 waiting, 0 bad / unknown / not in AJF |
| `controlm.job_counters.*` | Counts per state (ended_ok, ended_not_ok, executing, wait_*) |
| `controlm.job.number_of_runs` | How many times that job has run |

Alerting options from the extension: turn on **Send error events**, or build a metric event on `controlm.job.status` / `controlm.job_counters.ended_not_ok`.

### Process path (Control-M as software)

BMC documents wiring AppDynamics, Dynatrace, or Datadog to Control-M/EM, Server, Agent, and Automation API Java via `BMC_ADDITIONAL_JAVA_OPTIONS` / related properties. That watches the Control-M processes themselves, not each business job's OK / NOT OK.

### Safety note (OneAgent 1.327)

BMC flash (Jan 2026, CTM-13123): Dynatrace upgrade to **1.327** can crash Control-M/EM on Linux when APM is enabled. Until BMC ships a permanent fix, do **not** put OneAgent 1.327 on Control-M/EM Linux hosts. If it is already there, follow BMC KA 000446367.

## Result

| Goal | Do this |
|---|---|
| Understand the picture | Control-M schedules jobs. Dynatrace watches fail / hang / status / hosts. |
| Abend alert | Keep using log detectors (2026-10-12 seq 39). |
| Overrun alert | Keep pairing STARTED and ENDED (2026-10-12 seq 40, 41). |
| Live status without log parse | Add Hub extension Control-M Jobs v2 on an ActiveGate. |
| Protect EM | Block OneAgent 1.327 on Control-M/EM until BMC clears it. |

## Data flow map

```
                    ┌─ daily_ctmag / alert logs ──► Grail ──► DQL detectors ──► Problems
Control-M schedule ─┤
                    ├─ Automation API ──► ActiveGate (Jobs v2) ──► metrics / error events
                    └─ EM / Server / Agent Java ──► OneAgent ──► process health
                         (avoid OneAgent 1.327 on EM Linux)
```

## Related files

| File | Purpose |
|---|---|
| `1-dynatrace-control-m-overview.md` | This overview |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Paths and metrics |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `1.sh` | Git one-liners (not run) |
| 2026-10-12 seq 39 | Control-M abend alert Terraform |
| 2026-10-12 seq 40, 41 | Claim job overrun detector and explanation |
| Dynatrace docs | Control-M Jobs v2 extension |

## Commands

See `1.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/1-dynatrace-control-m-overview
git commit -m "dynatrace control-m overview"
git push
```
