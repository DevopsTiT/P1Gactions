# AXA ARB Splunk Dynatrace Migration

## Decision tree

```
Need facts from ARB pack P260120F?
  What is the project?
    Splunk → Dynatrace (AXA-GO SaaS) logging/monitoring migration
    Gate2 Build Permit + Cloud Permit — ARB 2026/06/26
  What changes technically?
    AS-IS: apps → S3 / agents → Splunk on ALJ MPI
    TO-BE: apps → Dynatrace (direct / OneAgent / Kinesis Firehose)
    Ex-ADL Local HUB added to Dynatrace log scope
    Post-migration: Splunk MPI servers decommissioned
  Who / when / cost?
    Presenter ROA Rosel (Ops Middleware and Monitoring)
    Cost 25M Yen (Gate 2); Production Q3-2026
  Where does impact land?
    Impacted platforms highlight: IT/IT Platform + Cloud
    D-PRA: Partner/SaaS + IaaS/PaaS/XaaS (Ops monitoring layer)
  Security / data?
    OneAccount SSO + RBAC to Dynatrace console (AXA-GO provided)
    Log path: App logs → Ingestion → Store → Query
    Retention: 3 months default; MyAXA example = 1 year
  Approval status from slides?
    PA done 2026/05/15; this pack = BP 2026/06/26
    Security Review Status still TBA (before Friday note on summary)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Project | **P260120F — Splunk to Dynatrace migration** (AXA Japan ARB) |
| Objective | Gate2 **Build Permit + Cloud Permit** |
| Why | Cut Splunk license/maintenance cost, shrink MPI server footprint, use AXA-GO standard Dynatrace |
| TO-BE hub | **Dynatrace SaaS** (AXA-GO dedicated tenant / OneAXA subscription) |
| New in scope | **Ex-ADL** servers / Local HUB application logs into Dynatrace |
| End state | Splunk MPI servers **decommissioned** after migration |
| Cost / timing | **25M Yen** (Gate 2); production **Q3-2026** |
| Presenter | ROA Rosel — Ops Middleware and Monitoring |
| This capture | Facts from the uploaded slides only (not a substitute for the full deck) |

---

## Summary

AXA Japan is seeking Gate2 Build + Cloud Permit approval to replace the MPI-hosted Splunk centralized logging stack with **AXA-GO Dynatrace SaaS**. Applications (OpenPaaS, Lambda via Firehose, MPI/POD, and newly in-scope Ex-ADL) send logs into Dynatrace. Ops use the Dynatrace console through OneAccount. After cutover, Splunk servers are removed. The pack shows PA already done (2026/05/15) and this session as BP (2026/06/26). Security review was still marked TBA on the summary sheet in the photos.

---

## Main content

### What this is (beginner)

**ARB** = Architecture Review Board. AXA Japan uses a slide template to approve architecture before build/cloud work.

**Gate2** here means **Build Permit + Cloud Permit** (solution approval), not the earlier concept/pre-assessment gates alone.

**Splunk (AS-IS)** = current centralized log search platform running on ALJ MPI servers, fed by S3 and agents.

**Dynatrace SaaS (TO-BE)** = AXA-GO provided monitoring/logging SaaS. AXA Japan uses a dedicated / OneAXA subscription instead of running Splunk servers.

**AXA-GO** = group shared platform/services organization providing Dynatrace, OneAccount, ActiveGates, etc.

### Project identity (title slide)

| Field | Value from slide |
| --- | --- |
| Title | Architecture Design Proposal for (P260120F - Splunk to Dynatrace migration) |
| Objective | Build Permit + Cloud Permit |
| Gate | Gate2 |
| Architecture Governance | Standard |
| Presenter (Team) | ROA Rosel (Ops Middleware and Monitoring) |
| Line of Business | OneAXA |
| ARB Date | 2026/06/26 |
| Engineering PoC | YASUDA Masayuki, HUNG Hsinyi, BARBASTE Nicolas |
| Ops PoC | YASUDA Masayuki |
| Platform Architecture PoC | ROA Rosel |
| Template | Architecture / AXA Japan (template ver.5.2) |
| Title slide last updated | 2026/06/22 09:00 |

### Approval matrix (slide 1 — proposal scope)

Gates / columns shown: **PA**, **BP\*1**, **Infra A**, **CP**, **IR**.

| Item meaning | What it is |
| --- | --- |
| PA | Prefunc assessment / Concept Approval — Gate1 |
| BP\*1 | Building Permit / Design Approval |
| Infra A | Infra Architecture Approval — Gate2 |
| CP | Cloud Permit |
| IR | Implementation Review — Post Gate2 |

Red box on the slide marks **this proposal scope** (今回の提案スコープ). Many rows are Mandatory for PA/BP/CP/IR; AI Governance is Mandatory only for AI solutions; Cloud Binding checklist is Mandatory for CP and n/a for PA/BP/IR.

Optional rows listed (not all filled as Mandatory): Project Charter, High Level Requirements, Solution Option Comparison, Interface List, Data Model, Operation Architecture.

### Architecture Design Summary Sheet (slide 3)

| Item | Answer from slide |
| --- | --- |
| Objective / Gate | Solution Approval / Gate2 |
| Archi Gov. | Standard |
| Background WHY | Decommission Splunk; migrate to Dynatrace (AXA-GO standard). Cut recurring cost (Splunk license + maintenance). Reduce MPI server footprint. Gain Dynatrace monitoring, analytics, observability. Align with enterprise standards and vendor consolidation via AXA-GO. |
| Architecture Design Overview | Provision AXA-GO Dynatrace (SaaS) as dedicated tenant. Instrument all applications to Dynatrace native logging; migrate Splunk monitoring/alerting to Dynatrace. Configure Ex-ADL servers for Dynatrace logging. Decommission Splunk MPI servers post-migration. |
| Alignment | Aligned with D-PRA / Architecture Roadmap |
| API | N/A |
| Cloud | Dynatrace |
| Project Cost | 25 (M Yen / Gate 2) |
| Production Release Timing | Q3-2026 |
| Security Review Status | TBA – before Friday |
| Architect View (in charge) | Supports migration to reduce MPI servers and centralize logs to Dynatrace SaaS, aligned with AXA-GO roadmap |
| Architect Name | (blank on photo) |
| Summary last updated | 2026/06/15 09:00 |

### Update and Approval History (slide 4)

**Key message:** For build/cloud permit approval.

| # | Item | Update detail |
| --- | --- | --- |
| 1 | Technical and Interface | Added detailed HLD for the migration |

| # | ARB Approval History (Date) | ARB Page Link (as shown) |
| --- | --- | --- |
| 1 | PA (2026/05/15) | OneAXA ARB: 2026/05/15 TBA / Splunk to Dynatrace Migration - AXA Japan IT – Confluence by AXA GO |
| 2 | BP (2026/06/26) | OneAXA ARB: 2026/06/26 P260120F / Splunk to Dynatrace migration - AXA Japan IT - Confluence by AXA GO – **THIS ARB** |
| 3 | IR (YYYY/MM/DD) | (blank — future) |
| 4 | CP (YYYY/MM/DD) | (blank on photo — Cloud Permit column may still need dating) |

Slide last updated: 2026/06/22 09:00.

---

### AS-IS architecture (slide 7 — Solution Context Diagram)

**Key messages**

| Message | What it means |
| --- | --- |
| MPI hosts Splunk | ALJ MPI runs Splunk for centralized application logging for ADJ and ALJ |
| OpenPaaS + Lambda → S3 → Splunk | Apps stream logs to AWS S3; Splunk ingests for search/analysis |

**AS-IS pic flow**

```
[AXA-GO OpenPaaS / SparkleCoral Cluster]
  Apps use Multi Log Forwarder → send to S3
        |
        v
[ALJ/ADJ AWS Account — S3]
  Logs from Lambda and OpenPaaS
        |
        v
[ALJ MPI — Splunk]  <--- center
   ^         ^         ^
   |         |         |
[AXA HQ Ops] [ADJ MPI Apps] [ALJ POD Apps]
                          [ALJAGU Local HUB Apps]
```

| Node | Role |
| --- | --- |
| AXA-GO OpenPaaS | App logs via Multi Log Forwarder to S3 |
| ALJ/ADJ AWS Account | S3 holding Lambda + OpenPaaS logs |
| ALJ MPI Splunk | Central ingest/search |
| AXA HQ (Shirokane) Operations | Ops users into Splunk |
| ADJ MPI / ALJ POD / ALJAGU Local HUB | Application sources |

---

### TO-BE architecture (slide 8 — Solution Context Diagram)

**Key messages**

| Message | What it means |
| --- | --- |
| Dynatrace replaces Splunk | Dynatrace SaaS from AXA-GO is the new hub |
| Ex-ADL in scope | Ex-ADL servers added for application logs into Dynatrace |

**TO-BE pic flow**

```
[AXA-GO OpenPaaS]
  Multi Log Forwarder → Dynatrace (direct)
        \
[ALJ/ADJ AWS — Kinesis Data Firehose] ----\
[ADJ MPI Applications] --------------------> [Dynatrace SaaS]  <--- hub (red box)
[ALJ POD Applications] --------------------/
[ALJAGU/ex-ADL Local HUB Applications] ---/
[AXA HQ Shirokane Operations] -----------> Dynatrace console
```

| Source | Path into Dynatrace |
| --- | --- |
| OpenPaaS apps | Multi Log Forwarder → Dynatrace directly |
| AWS Lambda / cloud logs | Kinesis Data Firehose → Dynatrace |
| ADJ MPI apps | Into Dynatrace (instrumentation / agents per HLD) |
| ALJ POD apps | Into Dynatrace |
| Ex-ADL / ALJAGU Local HUB | **New in scope** → Dynatrace |
| AXA HQ Ops | HTTPS via proxy to Dynatrace console |

Splunk box is gone from the center. Dynatrace SaaS is the single hub.

---

### Impacted Platforms (slide 9)

**Key message:** Dynatrace consolidates logging from system to application and speeds incident troubleshooting.

| Legend (from slide) | Meaning |
| --- | --- |
| Green outline | Reuse Shared Service provided by AXA GO |
| (other colors on legend) | Modification / New AXA / New external — as on slide |

**Highlighted boxes on the map (from photo):**

| Highlighted area | Note |
| --- | --- |
| **IT / IT Platform** (or IT4IT Platform) | Black rectangle — primary impacted platform row |
| **Cloud** | Black rectangle under Infrastructure & Cloud |

Most of the OneAXA domain map is shown green (reuse AXA-GO shared services). Business domains (insurance, engagement, etc.) appear as consumers of the shared IT/Cloud logging change rather than app rewrites.

---

### Alignment with Digital Platform Reference Architecture (slide 10)

**Key message:** Using Dynatrace (SaaS) for the application logging system.

**Highlighted on D-PRA diagram:**

| Layer | Highlight |
| --- | --- |
| UI | Partner / 3rd Party / SaaS |
| Platforms → Cloud / Infrastructure | IaaS / PaaS / XaaS |
| Platforms → Operations | Monitoring-Alerting / Capacity / Patch / BCP / Availability (context for Dynatrace) |

Dynatrace sits as an external SaaS / platform operations capability, not as a custom in-house API product (summary sheet API = N/A).

---

### Technical / HLD connectivity (slides 12 and 16)

Photos show the same family of HLD (slide 12 and a later duplicate-style slide 16). Readable structure:

```
[AXA-HQ Shirokane]
  IT members → Proxy --HTTPS--> [AXA-GO Dynatrace]
                                  Dynatrace Console
                                  Dynatrace API
                                  Dynatrace Grail
                                      |
                                      | HTTPS
                                      v
                         [AXA-GO Dynatrace ActiveGate]
                              ActiveGates (Tokyo etc.)
                                      |
                    TCP (e.g. 8443/9999 family on diagram)
                                      |
        +-------------+---------------+----------------+
        |             |               |                |
   [AXA-GO]     [TRS LocalHUB]  [AXA Japan LocalHUB]  ...
   ALJ-POD      Tokyo           ALJAGU apps
   App/DB       ex-ADL apps

[AXA Employee]
  AXA VPN --HTTPS--> [AXA-GO Support Tools]
                      OneAccount
                      Dynatrace Config Repository (via TV / bastion path)

[AXA-GO OpenPaaS Cluster]
  Tokyo / Singapore
  Public/Private subnets
  Multi Log Forwarder → egress → Dynatrace path

[ALJ / ADJ AWS Shared Account]
  VPC, Kinesis Data Firehose, CloudWatch Logs, AGU
  → applications / Firehose → Dynatrace

[ALJ / ADJ AWS MPI]
  EC2 / apps (Tokyo, Singapore noted)
  → into ActiveGate / Dynatrace path
```

| Concept | What the HLD is saying |
| --- | --- |
| Console access | HQ users via proxy HTTPS into Dynatrace SaaS |
| Identity for support tools | OneAccount (+ VPN for employees) |
| Runtime ingest | ActiveGates in region; TCP from local hubs / MPI / OpenPaaS |
| Cloud path | Firehose / CloudWatch / forwarders toward Dynatrace |
| Config | Dynatrace Config Repository via AXA-GO support tooling |

Exact port numbers and every box label may need the native PPT for pixel-perfect inventory; the photos confirm ActiveGate, Firehose, Multi Log Forwarder, OneAccount, and multi-site Tokyo/Singapore.

---

### Data Architecture (slide 13)

**Key messages**

| Message | What it means |
| --- | --- |
| Three storage layers | Ingestion → Store → Query processing |
| Default retention | **3 months** |
| Longer retention | Per application as needed; example **MyAXA = 1 year** |

**Log path (pic)**

```
[Application Logs] → [Dynatrace Ingestion] → [Dynatrace Store] → [Dynatrace Query Engine]
                           (OneAXA side)         buckets/tables/views
                                                 timestamp + raw log data
```

**Application log sources listed on slide**

| # | Source |
| --- | --- |
| 1 | AWS Lambda logs |
| 2 | OpenPaaS Application logs |
| 3 | MPI/POD application logs |
| 4 | LocalHUB (ALJAGU/ex-ADL) application logs |

Legend on slide: API (solid), Batch (dashed), Manual (dotted).

Slide last updated: 2026/06/25 09:50.

---

### Security Architecture (slide 19)

| Field | Value |
| --- | --- |
| Key Message | Using **OneAccount** login to Dynatrace (SaaS) |
| IAM CoE Demand # | Already integrated as provided by AXA-GO |

**Access pic**

```
[I&T members @ AXA-HQ Shirokane]
        |
        | (get AXA OneAccount)
        v
[AXA-GO OneAccount] ----auth/RBAC----> [Dynatrace Web Console]
                                              |
                                              v
                                       [Dynatrace Store]
```

| Control | What it means |
| --- | --- |
| OneAccount | Enterprise SSO into Dynatrace |
| RBAC | Role-based access on the Dynatrace console |
| AXA-GO provided | IAM integration not invented by this project |

Slide last updated: 2026/06/25 09:00.

---

### Facts still open or incomplete on the photos

| Gap | Evidence on slides |
| --- | --- |
| Security Review Status | Summary says **TBA – before Friday** |
| Architect Name | Blank on summary photo |
| IR / CP dated approval rows | Placeholders YYYY/MM/DD on history slide |
| Impacted Applications detail | Matrix says Mandatory for PA/BP; detailed app list slide not in this photo set |
| Full NFR / Key Tech / Cost breakdown slides | Marked Mandatory\*2 on matrix; not fully captured in these images |
| Decommission Plan | Mandatory for BP/Infra A on matrix; not in this photo set |
| Cloud Binding Principles Checklist | Mandatory for CP; not in this photo set |

---

## Data flow map

```
AS-IS
  OpenPaaS / Lambda → S3 → Splunk (ALJ MPI)
  ADJ MPI / ALJ POD / Local HUB → Splunk
  Ops (HQ) → Splunk

TO-BE
  OpenPaaS Multi Log Forwarder ──┐
  Kinesis Data Firehose ─────────┤
  ADJ MPI apps ──────────────────┼──> Dynatrace SaaS (AXA-GO)
  ALJ POD apps ──────────────────┤         │
  Ex-ADL / Local HUB ────────────┘         │
                                           v
                              Ingestion → Store → Query
                              Retention 3mo default (MyAXA 1y example)
                                           ^
  Ops (HQ) → Proxy / OneAccount + RBAC ────┘
  ActiveGates (Tokyo/…) bridge VPC/MPI/HUB traffic

POST
  Decommission Splunk MPI servers
```

---

## Related files

| File | Purpose |
| --- | --- |
| [10.sh](./10.sh) | Echo checklist for this capture (no live AXA systems) |
| [10-axa-arb-splunk-dynatrace-migration-follow.txt](./10-axa-arb-splunk-dynatrace-migration-follow.txt) | Chat-ready full capture |
| Source | User-uploaded ARB PowerPoint screenshots (slides 1–4, 7–10, 12–13, 16, 19) |
| Related Dynatrace/PD work | Daily Files `2026-08-31/7-pagerduty-event-orchestration-poc/` (alerting after Dynatrace exists) |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/10-axa-arb-splunk-dynatrace-migration/` |

---

## Commands

No live AXA/Dynatrace commands. Checklist echoes are in [10.sh](./10.sh).

```bash
echo "Captured: P260120F Splunk to Dynatrace Gate2 Build+Cloud Permit ARB 2026/06/26"
```
