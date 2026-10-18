# Monitoring Error And Availability Rates

## Decision tree

```
What is the business asking?
 "Is the service up?"           → availability (or success rate)
 "How often do calls fail?"     → error rate
 "Is it slow?"                  → latency (p50 / p95 / p99)
 "How busy is it?"              → request rate / throughput
 "Are we burning the SLO?"      → error budget from availability or success SLI
 Alert noisy?
   → prefer burn-rate on SLO, not raw error spikes alone
   → separate user-facing errors from dependency / 4xx noise
```

## Short takeaway

| Rate | Plain meaning | Typical formula |
|---|---|---|
| Availability | Share of time (or requests) that worked well enough | Successful / total, or uptime / window |
| Error rate | Share of requests that failed | Errors / total requests |
| Success rate | Share that succeeded | 1 − error rate (same window) |
| Request rate | How many requests per second | Count / time |
| Latency | How long a request took | Percentiles: p50, p95, p99 |

## Summary

In monitoring, these rates are **ratios over a time window**. Availability and error rate describe health. Latency and request rate describe speed and load. You turn the important ratios into **SLIs**, set **SLO** targets, and alert when the **error budget** burns too fast.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Metric | A number measured over time (count, gauge, histogram). | What dashboards plot. |
| Time window | The period you measure (1m, 5m, 30d). | Same rate looks different on different windows. |
| Request | One call from a user or another service. | Common unit for error and success rates. |
| Good / bad event | Your rule for success vs failure. | Must be defined before the formula means anything. |
| SLI | Service Level Indicator. The measured ratio. | The number you watch. |
| SLO | Service Level Objective. The target for that SLI. | Example: 99.9% availability over 30 days. |
| Error budget | Allowed failure room = 100% − SLO. | How much bad you can afford. |
| Percentile | Value below which X% of samples fall. | p99 = 99% of requests were faster than this. |

### The four golden signals (mental model)

Most service monitoring starts from these four ideas (Google SRE style):

| Signal | Question it answers | Common rate / shape |
|---|---|---|
| Traffic | How much work arrives? | Request rate (req/s) |
| Errors | How much work fails? | Error rate (%) |
| Latency | How slow is work? | Latency percentiles (ms) |
| Saturation | How full are resources? | CPU %, queue depth, disk % |

Availability is the "is it good enough for users?" view. It is often built from errors and sometimes from latency (slow can count as failed).

---

### 1. Request rate (traffic)

**What it is:** How many requests (or jobs, messages) you see per unit time.

```
request_rate = request_count / time_window
```

| Example | Meaning |
|---|---|
| 200 req/s | About 200 HTTP calls each second |
| 0 req/s on a busy service | Often a probe or routing problem, not "perfect health" |

**Why you care:** Error % can look fine while traffic is zero. Always read error rate **with** traffic.

---

### 2. Error rate

**What it is:** Fraction of requests that count as errors in your definition.

```
error_rate = error_count / total_requests
```

Often shown as a percent:

```
error_rate_% = 100 × error_count / total_requests
```

| You must decide what "error" means | Examples |
|---|---|
| HTTP | 5xx only, or 5xx + timeouts, or 5xx + some 4xx |
| gRPC | Non-OK status codes you care about |
| Jobs | Failed / abend / Ended Not OK |
| Synthetic check | Probe failed |

**Examples**

| Window | Total | Errors | Error rate |
|---|---|---|---|
| 5 minutes | 10,000 | 50 | 0.5% |
| 5 minutes | 10,000 | 500 | 5% |

**Common traps**

| Trap | What happens | Better practice |
|---|---|---|
| Counting all 4xx as errors | Login typos inflate error rate | Separate client errors (4xx) from server errors (5xx) |
| Tiny window + tiny traffic | 1 failure in 2 requests = 50% | Use longer window or burn-rate alerts |
| Mixing internal retries | One user failure counted many times | Prefer user-facing or idempotent success definitions |

---

### 3. Success rate

**What it is:** The flip side of error rate for the same definition.

```
success_rate = successful_count / total_requests
success_rate = 1 − error_rate
```

| Error rate | Success rate |
|---|---|
| 0.1% | 99.9% |
| 1% | 99% |

Many "availability" SLIs for APIs are really **success rate over requests**, not "server ping up."

---

### 4. Availability rate

**What it is:** How often the service was usable for users in a window.

There are two common styles:

#### A) Request-based availability (most APIs)

```
availability = successful_requests / total_requests
```

Same math as success rate. You may also mark **too-slow** requests as failed (see latency below).

#### B) Time-based availability (binary up/down)

```
availability = uptime / (uptime + downtime)
```

| Style | Good for | Weak for |
|---|---|---|
| Request-based | APIs with steady traffic | Quiet overnight services (few requests) |
| Time-based | "Was the site up?" probes every minute | Partial failures (half of regions broken) |

**Example SLO language**

| SLO text | What it usually means |
|---|---|
| 99.9% availability over 30 days | At most 0.1% of requests (or of probe minutes) may fail |
| 99.99% | Much less allowed failure (about 4.3 minutes/month time-based) |

Rough **time-based** budgets for 30 days (~43,200 minutes):

| Availability SLO | Allowed downtime (approx.) |
|---|---|
| 99% | ~7.2 hours |
| 99.9% | ~43 minutes |
| 99.99% | ~4.3 minutes |

For **request-based**, budget is about failed requests, not clock minutes.

---

### 5. Latency (and "slow is broken")

**What it is:** How long requests take. Not a rate, but always shown next to rates.

| Stat | Meaning |
|---|---|
| p50 (median) | Half of requests faster than this |
| p95 | 95% faster than this |
| p99 | 99% faster than this |
| Average | Easy to skew by a few huge outliers |

**Availability link:** Teams often define:

```
good request = not an error AND latency < threshold
availability = good_requests / total_requests
```

Example: HTTP 200 that took 30 seconds may count as **bad** for the user SLI.

---

### 6. Error budget (ties the rates to ops)

```
SLO = 99.9% availability
error_budget = 100% − 99.9% = 0.1%
```

| If 30-day success is | Budget left |
|---|---|
| 99.95% | Still some room |
| 99.9% | Budget empty |
| 99.8% | Over budget (reliability debt) |

**Burn rate (idea):** How fast you are spending that budget. Fast burn → page. Slow burn → ticket.

---

### 7. Other rates you will see on dashboards

| Name | Formula idea | Use |
|---|---|---|
| Apdex | Satisfied + tolerant/2 over total | User happiness score (0–1) |
| Saturation | Used / capacity | CPU, memory, thread pool, queue |
| Queue rate / lag | Messages waiting or consumer lag | Async / Kafka style systems |
| Job failure rate | Failed jobs / total jobs | Batch / Control-M style |
| Probe failure rate | Failed checks / total checks | Synthetic monitoring |

---

### How they sit together on one service

```
Users / callers
    │
    ▼
Request rate ──────────────────────────────► "how busy"
    │
    ├── success ──► success rate ──┐
    │                              ├──► availability SLI ──► SLO / error budget
    ├── error ────► error rate ────┘
    │
    └── duration ─► latency p50/p95/p99 ──► (optional: slow = bad)
```

| Dashboard row | Healthy example | Worry example |
|---|---|---|
| Request rate | Steady or expected spike | Sudden drop to near zero |
| Error rate | Under SLO (e.g. &lt; 0.1%) | Jump to 2–5% with real traffic |
| Latency p99 | Under target (e.g. &lt; 500 ms) | p99 climbing while p50 flat (tail issue) |
| Availability | At or above SLO | Below SLO / budget burning |

## Result

| Term | One-line meaning |
|---|---|
| Error rate | Failed / total |
| Success rate | Succeeded / total |
| Availability | Usable share (often same as success, sometimes time-based) |
| Request rate | Load per second |
| Latency | How long; use percentiles |
| Error budget | Allowed failure room under the SLO |

When someone says "check the error rate and availability," they mean: **are users succeeding often enough, and how bad are failures right now**, always read with **traffic** and **latency**.

## Data flow map

```
Emit metrics (app / mesh / load balancer / synthetic)
  → store (Dynatrace / Prometheus / CloudWatch / …)
  → calculate rates over a window
       request_rate = count / time
       error_rate   = errors / total
       availability = good / total   (or uptime ratio)
  → compare to SLO
  → alert on burn / threshold
  → dashboard for humans
```

## Related files

| File | Purpose |
|---|---|
| `5-monitoring-error-availability-rates.md` | This explanation |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Scope notes |
| `2-result.md` | Cheat sheet |
| `3-glossary.md` | Terms |
| `5.sh` | Git one-liners (not run) |

## Commands

See `5.sh`. None of these commands have been run. No live queries are required for this concept answer.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/5-monitoring-error-availability-rates
git commit -m "monitoring error and availability rates explained"
git push
```
