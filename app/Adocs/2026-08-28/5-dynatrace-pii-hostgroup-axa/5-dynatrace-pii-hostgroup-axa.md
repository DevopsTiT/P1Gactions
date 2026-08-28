# Dynatrace PII Filtering By Host Group

```
Prod-HostGroupUpdate spreadsheet row
  │
  ├─ App is HR / Customer MDM / Tax?
  │     └─ HIGH PII → Phase 1 (mask before Grail + app review)
  │
  ├─ App is HULFT / FTP SSTB?
  │     └─ MEDIUM (payload in transit) → Phase 1b (mask filenames, paths, tokens)
  │
  ├─ App is imageWARE / EIP / BC calc / DFS?
  │     └─ LOW–MEDIUM → Phase 2 (standard email/phone/My Number + field remove)
  │
  └─ Host in C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE only?
        └─ Split rules by hostname — same host group holds HR and infra
```

```
Where to attach the rule?
  │
  ├─ OneAgent on host → host group matcher (dt.host_group.id)
  │     └─ Best for capture-time mask before data leaves server
  │
  ├─ OpenPipeline route → host.name OR dt.entity.host OR log attribute
  │     └─ Best central backstop for all ingest paths
  │
  ├─ Management zone → access control (who sees which hosts)
  │     └─ Complements masking — does not replace it
  │
  └─ Grail bucket retention → shorter keep for high-PII apps
        └─ After masking is proven
```

| Question | Answer |
| --- | --- |
| What is this guide scoped to? | Production hosts from **Prod-HostGroupUpdate 1 - Kim** (HostNames sheet) |
| Primary scope key | `dt.host_group.id` (OneAgent host group) plus `host.name` |
| Highest PII apps | People Soft HR, Customer MDM, Tax Payment Report Management |
| Planned rollout date | **8/20/2026** (per spreadsheet); verify and close gaps if past due |
| App owner for validation | **Magaki** (all visible rows) |

## Summary

Use your spreadsheet as the **scope map**: each hostname belongs to a Dynatrace host group (`dt.host_group.id`). Apply **OneAgent sensitive data masking** on the host (capture-time), **OpenPipeline** routes and DQL processors at ingest (central policy), and **DQL verification queries** filtered by `host.name` or host group. Roll out in **risk order** — HR and customer data first — with **Magaki** signing off per application that logs no longer show raw PII.

This builds on the general Dynatrace PII guide in seq 1 (`1-dynatrace-logs-pii-filter`); here every example is tied to your ALJ production inventory.

---

## Inventory from spreadsheet (visible rows)

| Hostname | dt.host_group.id | Application name | Owner | Planned date |
| --- | --- | --- | --- | --- |
| `*-HFTP-01.ads-jp.intraxa` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | FTP SSTB [TS] | Magaki | 8/20/2026 |
| `S-HQFS-01.ads-jp.intraxa` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | DFS [TS] | Magaki | 8/20/2026 |
| `EAA0059.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | People Soft Human Resources Management | Magaki | 8/20/2026 |
| `EAA006B.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Customer Master Data Management | Magaki | 8/20/2026 |
| `EAA006F.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Enterprise Integration Platform | Magaki | 8/20/2026 |
| `EAA007F.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | Magaki | 8/20/2026 |
| `EAA0080.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | Magaki | 8/20/2026 |
| `EAA0081.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | Hulft [TS] | Magaki | 8/20/2026 |
| `EAA0088.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` | Tax Payment Report Management | Magaki | 8/20/2026 |
| `EAA008F.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` | imageWARE Form Manager | Magaki | 8/20/2026 |
| `EAA0090.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` | imageWARE Form Manager | Magaki | 8/20/2026 |
| `EAA0091.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` | imageWARE Form Manager | Magaki | 8/20/2026 |
| `EAA0092.PRPRIVMGMT.intra` | `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` | imageWARE Form Manager | Magaki | 8/20/2026 |
| `CEAA101D.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | BC calc | Magaki | 8/20/2026 |

**Note:** Four imageWARE hosts are highlighted in red in the sheet — treat as priority validation targets.

### Host groups (unique)

| dt.host_group.id | Host count (visible) | Apps on this group |
| --- | --- | --- |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | 6 | FTP, DFS, People Soft HR, Customer MDM, EIP, BC calc |
| `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | 3 | Hulft [TS] |
| `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` | 1 | Tax Payment Report Management |
| `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` | 4 | imageWARE Form Manager |

**Important:** `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` mixes **high-PII apps** (HR, MDM) with **infra/low** (FTP, DFS, BC calc). You cannot use host group alone for HR — add **hostname** or **process group / service** matchers.

---

## PII risk tiers (decision tree)

| Tier | Applications | Why | Masking priority |
| --- | --- | --- | --- |
| **High** | People Soft HR | Employee names, IDs, addresses, payroll, My Number risk | Phase 1 — week of 8/20/2026 |
| **High** | Customer Master Data Management | Customer names, contact info, account IDs | Phase 1 |
| **High** | Tax Payment Report Management | Taxpayer IDs, financial account numbers, report metadata | Phase 1 |
| **Medium** | Hulft [TS] | File transfer logs may echo filenames, paths, or payload snippets | Phase 1b |
| **Medium** | FTP SSTB [TS] | Same as file transfer — path and credential risk | Phase 1b |
| **Medium** | imageWARE Form Manager | Form data, scanned document metadata, user IDs on forms | Phase 2 |
| **Low** | Enterprise Integration Platform | Mostly integration IDs; occasional message body in errors | Phase 2 |
| **Low** | DFS [TS] | File paths; rarely direct PII unless misconfigured | Phase 3 |
| **Low** | BC calc | Calculation logs; scope to numeric IDs only if present | Phase 3 |

---

## Application → likely PII in logs

| Application | PII types likely in logs | Example log patterns to target |
| --- | --- | --- |
| People Soft HR | Employee name | `employee_name=`, kanji names in free text |
| People Soft HR | Employee ID | `EMPLID`, `employee_id=` |
| People Soft HR | National ID (My Number) | 12-digit sequences, `mynumber`, `個人番号` |
| People Soft HR | Email / phone | `email=`, `phone=`, `@` in HR context |
| Customer MDM | Customer name | `customer_name`, `CUST_NAME` |
| Customer MDM | Address | postal codes, `address=`, `ADDR` |
| Customer MDM | Account / customer ID | `customer_id`, `CUST_ID` |
| Tax Payment Report | Taxpayer ID | `taxpayer_id`, `法人番号`, `TIN` |
| Tax Payment Report | Bank / account numbers | long digit runs, `account_no` |
| Tax Payment Report | Report reference | may embed IDs — mask digit groups |
| Hulft / FTP SSTB | File paths with names | `/data/hr/`, `.csv` paths with person names |
| Hulft / FTP SSTB | Transfer credentials | `password=`, `user=` in connection logs |
| imageWARE | Form field values | `field=`, JSON keys with applicant data |
| imageWARE | Document IDs tied to person | barcode / doc ref with PII |
| EIP | Message payloads in errors | XML/JSON fragments with customer or employee IDs |
| DFS / BC calc | Usually low | mask email/phone as baseline anyway |

---

## How to scope rules (four dimensions)

| Dimension | Dynatrace attribute | Example for this inventory |
| --- | --- | --- |
| Host group | `dt.host_group.id` on host entity; OneAgent rule scope **Host group** | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` |
| Hostname | `host.name` in logs | `EAA0059.PRPRIVMGMT.intra` |
| Hostname pattern | `matchesValue(host.name, "EAA0059*")` or `in(host.name, {...})` | HR host only inside shared infra group |
| Log source | `log.source` | `/var/log/hulft/*.log`, PeopleSoft `APP_*` log path |
| Process group | `dt.process_group.name` | `PeopleSoft App Server` |
| Service | `service.name` | if instrumented — use for OpenPipeline route |
| Custom tag | Host custom metadata from host group update project | `application=PeopleSoft-HR` if you add it |

**Rule of thumb:** use **host group** for HULFT, Tax, and imageWARE (one app family per group). Use **host.name** (or process group) for hosts in `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`.

---

## Step-by-step for this environment

### Step 1 — Confirm host groups in Dynatrace

1. **Hosts** → pick `EAA0059.PRPRIVMGMT.intra` → verify **Host group** = `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`.
2. Repeat for one host per distinct `dt.host_group.id` from the table.
3. If host group does not match the spreadsheet, finish the host group migration first — masking rules depend on correct grouping.

### Step 2 — OneAgent sensitive data masking (per host group / host)

**Navigation:** Settings → Collect and capture → Log monitoring → Sensitive data masking

Create **separate rules** — do not rely on one global regex for all ALJ production.

#### Rule set A — `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` (Tax)

| Setting | Value |
| --- | --- |
| Scope | Host group = `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` |
| Enable built-in | Payment card (if applicable) |
| Custom regex 1 | Long digit runs (13–19) → `XXXX-XXXX-XXXX-XXXX` |
| Custom regex 2 | `\b\d{12}\b` (My Number shape — legal review) → `************` |
| Custom regex 3 | `taxpayer_id\s*=\s*\S+` → `taxpayer_id=***` |
| Matcher optional | `host.name` = `EAA0088.PRPRIVMGMT.intra` |

#### Rule set B — `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` (Hulft)

| Setting | Value |
| --- | --- |
| Scope | Host group = `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` |
| Mask | `password=`, `passwd=`, `Bearer\s+\S+` |
| Mask | File paths: regex on `/.*\.(csv|txt|xml|dat)/` → `/***masked***/` |
| Hosts | `EAA007F`, `EAA0080`, `EAA0081` |

#### Rule set C — `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE`

| Setting | Value |
| --- | --- |
| Scope | Host group = `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE` |
| Remove fields | `form_data`, `applicant_name`, `address` if structured JSON logs |
| Mask | Email and phone patterns in `content` |
| Priority hosts | `EAA008F`, `EAA0090`, `EAA0091`, `EAA0092` (red in sheet) |

#### Rule set D — High PII on shared infra host group (hostname-scoped)

For `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`, scope by **host.name**:

| Host | App | Minimum masks |
| --- | --- | --- |
| `EAA0059.PRPRIVMGMT.intra` | People Soft HR | employee ID, email, phone, 12-digit ID, names in `EMPLID` context |
| `EAA006B.PRPRIVMGMT.intra` | Customer MDM | customer_id, email, phone, address fields |
| `EAA006F.PRPRIVMGMT.intra` | EIP | mask JSON/XML body snippets in error logs |
| `*-HFTP-01.ads-jp.intraxa` | FTP SSTB | credentials, remote paths with filenames |
| `S-HQFS-01.ads-jp.intraxa` | DFS | paths only (baseline) |
| `CEAA101D.PRPRIVMGMT.intra` | BC calc | baseline email/phone |

**OneAgent matcher example (UI):** Host name equals `EAA0059.PRPRIVMGMT.intra`.

### Step 3 — OpenPipeline routes (central ingest)

**Navigation:** Settings → Process and contextualize → OpenPipeline → Logs → Routes

Create routes that send logs to app-specific pipelines **before** default storage.

| Route name | Matching condition (DQL) | Pipeline |
| --- | --- | --- |
| `route-tax-payment` | `matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP")` | `pipeline-pii-tax` |
| `route-hulft` | `matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")` | `pipeline-pii-hulft` |
| `route-imageware` | `matchesValue(dt.host_group.id, "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE")` | `pipeline-pii-imageware` |
| `route-peoplesoft-hr` | `matchesValue(host.name, "EAA0059.PRPRIVMGMT.intra")` | `pipeline-pii-peoplesoft-hr` |
| `route-customer-mdm` | `matchesValue(host.name, "EAA006B.PRPRIVMGMT.intra")` | `pipeline-pii-customer-mdm` |

If `dt.host_group.id` is not on the log record, use:

```text
matchesValue(host.name, "EAA0088.PRPRIVMGMT.intra")
```

or join via host entity in notebooks; at ingest, `host.name` is usually present.

### Step 4 — OpenPipeline DQL processors (examples)

**Pipeline `pipeline-pii-peoplesoft-hr`** — processor matching `host.name`:

```text
fieldsAdd content = replacePattern(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "xxx@xxx.xxx")
| fieldsAdd content = replacePattern(content, "EMPLID[=:\\s]+[A-Z0-9]+", "EMPLID=***")
| fieldsAdd content = replacePattern(content, "\\b\\d{12}\\b", "************")
| fieldsAdd content = replacePattern(content, "(?i)(password|token)\\s*[=:]\\s*\\S+", "$1=***")
```

**Pipeline `pipeline-pii-customer-mdm`:**

```text
fieldsAdd content = replacePattern(content, "(?i)customer_id[=:\\s]+\\S+", "customer_id=***")
| fieldsAdd content = replacePattern(content, "(?i)(phone|tel)[=:\\s]+[\\d\\-+\\s]+", "$1=***")
| fieldsAdd content = replacePattern(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "xxx@xxx.xxx")
```

**Pipeline `pipeline-pii-tax`:**

```text
fieldsAdd content = replacePattern(content, "(?i)taxpayer_id[=:\\s]+\\S+", "taxpayer_id=***")
| fieldsAdd content = replacePattern(content, "\\b(?:\\d[ -]*?){13,19}\\b", "XXXX-XXXX-XXXX-XXXX")
| fieldsAdd content = replacePattern(content, "\\b\\d{12}\\b", "************")
```

**Pipeline `pipeline-pii-hulft`:**

```text
fieldsAdd content = replacePattern(content, "(?i)(password|passwd|user)[=:\\s]+\\S+", "$1=***")
| fieldsAdd content = replacePattern(content, "/[^\\s]+\\.(csv|txt|xml|dat)", "/***masked***/file.$1")
```

**Pipeline `pipeline-pii-imageware`:**

```text
fieldsRemove applicant_name, form_data, address, postal_code
| fieldsAdd content = replacePattern(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "xxx@xxx.xxx")
```

Always **Run sample data** with realistic (synthetic) PII before save.

### Step 5 — Management zones and retention (optional hardening)

| Control | Use for this inventory |
| --- | --- |
| Management zone `MZ-ALJ-PII-HIGH` | Members: HR, MDM, Tax hosts — restrict dashboard access |
| Management zone `MZ-ALJ-PII-MEDIUM` | Hulft, FTP, imageWARE |
| Grail bucket retention | Shorter retention on high-PII buckets after masking verified |
| Log ingest rules | Drop debug-level logs on HR hosts to reduce exposure surface |

Management zones **do not mask** data — they limit who can query it. Still mask at capture or ingest.

---

## Terraform examples (host group variables)

Save as `5-dynatrace-pii-hostgroup-axa-variables.tf` pattern — use your Dynatrace provider version.

```hcl
variable "host_groups" {
  type = map(string)
  default = {
    infra_base   = "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"
    hulft        = "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP"
    tax_payment  = "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP"
    imageware    = "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  }
}

variable "high_pii_hosts" {
  type = map(string)
  default = {
    peoplesoft_hr = "EAA0059.PRPRIVMGMT.intra"
    customer_mdm  = "EAA006B.PRPRIVMGMT.intra"
    tax_payment   = "EAA0088.PRPRIVMGMT.intra"
  }
}

variable "hulft_hosts" {
  type    = list(string)
  default = [
    "EAA007F.PRPRIVMGMT.intra",
    "EAA0080.PRPRIVMGMT.intra",
    "EAA0081.PRPRIVMGMT.intra",
  ]
}

variable "imageware_hosts" {
  type    = list(string)
  default = [
    "EAA008F.PRPRIVMGMT.intra",
    "EAA0090.PRPRIVMGMT.intra",
    "EAA0091.PRPRIVMGMT.intra",
    "EAA0092.PRPRIVMGMT.intra",
  ]
}
```

**OneAgent masking — Tax host group:**

```hcl
resource "dynatrace_log_sensitive_data_masking" "tax_payment_pii" {
  name    = "mask-tax-payment-${var.host_groups.tax_payment}"
  enabled = true
  scope   = "HOST_GROUP"
  host_group = var.host_groups.tax_payment

  masking {
    type        = "STRING"
    expression  = "(?i)taxpayer_id\\s*=\\s*\\S+"
    replacement = "taxpayer_id=***"
  }

  masking {
    type        = "STRING"
    expression  = "\\b\\d{12}\\b"
    replacement = "************"
  }
}
```

**OneAgent masking — People Soft HR (host-scoped inside infra group):**

```hcl
resource "dynatrace_log_sensitive_data_masking" "peoplesoft_hr_pii" {
  name    = "mask-peoplesoft-hr-${var.high_pii_hosts.peoplesoft_hr}"
  enabled = true
  scope   = "HOST"
  host    = var.high_pii_hosts.peoplesoft_hr

  masking {
    type        = "STRING"
    expression  = "EMPLID[=:\\s]+[A-Z0-9]+"
    replacement = "EMPLID=***"
  }

  masking {
    type        = "STRING"
    expression  = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
    replacement = "xxx@xxx.xxx"
  }
}
```

**OpenPipeline route — HULFT host group:**

```hcl
resource "dynatrace_openpipeline_v2_logs_routes" "route_hulft" {
  display_name = "route-hulft-pii"
  custom_id    = "route_hulft_pii"

  route {
    pipeline_id = dynatrace_openpipeline_v2_logs_pipelines.pipeline_hulft.custom_id
    matcher     = "matchesValue(dt.host_group.id, \"${var.host_groups.hulft}\")"
    enabled     = true
  }
}

resource "dynatrace_openpipeline_v2_logs_pipelines" "pipeline_hulft" {
  display_name = "pipeline-pii-hulft"
  custom_id    = "pipeline_pii_hulft"

  processing {
    processors {
      processor {
        type        = "dql"
        id          = "mask_hulft_secrets"
        description = "Mask credentials and file paths on HULFT hosts"
        matcher     = "true"
        enabled     = true
        dql {
          script = <<-EOT
            fieldsAdd content = replacePattern(content, "(?i)(password|passwd|user)[=:\\s]+\\S+", "$1=***")
            | fieldsAdd content = replacePattern(content, "/[^\\s]+\\.(csv|txt|xml|dat)", "/***masked***/file.$1")
          EOT
        }
      }
    }
  }
}
```

Validate attribute names (`host_group`, `host`, `scope`) against your provider version — schemas differ slightly between releases.

---

## Verification DQL (scoped to your inventory)

Run in **Logs and Events → Advanced mode** or a **Notebook**. Commands also in `5.sh`.

**1. Confirm logs arrive from each host group (last 24h):**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| summarize count(), by: { dt.host_group.id, host.name }
| sort count desc
```

**2. Hunt raw email on HR host (should trend to zero after masking):**

```text
fetch logs, from: now()-1h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "@")
| filter not matchesPhrase(content, "xxx@xxx.xxx")
| fields timestamp, content, log.source
| limit 20
```

**3. Hunt EMPLID on People Soft host:**

```text
fetch logs, from: now()-1h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "EMPLID")
| filter not matchesPhrase(content, "EMPLID=***")
| limit 20
```

**4. Tax host — taxpayer_id leak check:**

```text
fetch logs, from: now()-1h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "taxpayer_id")
| filter not matchesPhrase(content, "taxpayer_id=***")
| limit 20
```

**5. HULFT — password in clear text:**

```text
fetch logs, from: now()-1h
| filter in(host.name, {
    "EAA007F.PRPRIVMGMT.intra",
    "EAA0080.PRPRIVMGMT.intra",
    "EAA0081.PRPRIVMGMT.intra"
  })
| filter matchesPhrase(content, "password=")
| filter not matchesPhrase(content, "password=***")
| limit 20
```

**6. imageWARE hosts (red priority):**

```text
fetch logs, from: now()-1h
| filter in(host.name, {
    "EAA008F.PRPRIVMGMT.intra",
    "EAA0090.PRPRIVMGMT.intra",
    "EAA0091.PRPRIVMGMT.intra",
    "EAA0092.PRPRIVMGMT.intra"
  })
| filter matchesPhrase(content, "@")
| filter not matchesPhrase(content, "xxx@xxx.xxx")
| limit 20
```

**7. Confirm OpenPipeline ran (post-ingest):**

```text
fetch logs, from: now()-1h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter isNotNull(dt.openpipeline.pipelines)
| fields timestamp, dt.openpipeline.pipelines, content
| limit 10
```

---

## Rollout plan (aligned to 8/20/2026)

| Phase | Target date | Scope | Actions |
| --- | --- | --- | --- |
| **0 — Prep** | Before 8/20 | All hosts | Confirm host groups match spreadsheet; synthetic PII test strings agreed with Magaki |
| **1 — High PII** | 8/20/2026 | `EAA0059`, `EAA006B`, `EAA0088` | OneAgent host-scoped rules + OpenPipeline pipelines; verification DQL queries 2–4 |
| **1b — Transfer** | 8/20–8/22 | HULFT + FTP hosts | Credential and path masking; queries 5 + FTP host check |
| **2 — Middleware** | 8/23–8/27 | imageWARE + EIP | Field remove + email mask; query 6 |
| **3 — Infra low** | 8/28+ | DFS, BC calc | Baseline patterns only |
| **4 — Steady state** | Weekly | All | Magaki spot-check per app; Sensitive Data Center scan if licensed |

If today is past 8/20/2026, run **gap assessment** first: execute verification queries — any non-zero leak counts mean that phase is not done.

---

## Owner handoff (Magaki)

| Application | Host(s) | Magaki validates |
| --- | --- | --- |
| People Soft HR | `EAA0059` | No raw EMPLID, email, phone, or 12-digit IDs in sample logs |
| Customer MDM | `EAA006B` | No raw customer_id or contact fields |
| Tax Payment | `EAA0088` | No raw taxpayer_id or account numbers |
| Hulft | `EAA007F`, `EAA0080`, `EAA0081` | No passwords; file paths masked |
| FTP SSTB | `*-HFTP-01` | No credentials in transfer logs |
| imageWARE | `EAA008F`–`EAA0092` | No form PII fields; red hosts first |
| EIP | `EAA006F` | Error logs do not dump full message bodies |
| DFS / BC calc | `S-HQFS-01`, `CEAA101D` | Baseline check only |

**Handoff template for Magaki:**

1. Run verification DQL for your app hosts (section above).
2. Export 5 sample masked log lines (screenshot or notebook).
3. Sign off in the change ticket for **Prod-HostGroupUpdate**.
4. If leaks remain, open app ticket to stop logging at source — masking is backup.

---

## Data flow map

```
Spreadsheet row (hostname + dt.host_group.id + app name)
        │
        ▼
OneAgent on PRPRIVMGMT / ads-jp host
        │
        ├─ Host group matcher (HULFT, Tax, imageWARE)
        ├─ Host name matcher (HR, MDM inside INFRA_BASE group)
        └─ Sensitive data masking (regex before send)
        │
        ▼
OpenPipeline route (dt.host_group.id or host.name)
        │
        ├─ pipeline-pii-peoplesoft-hr
        ├─ pipeline-pii-customer-mdm
        ├─ pipeline-pii-tax
        ├─ pipeline-pii-hulft
        └─ pipeline-pii-imageware
        │
        ▼
Grail log storage (masked)
        │
        ├─ Management zone MZ-ALJ-PII-* (access control)
        ├─ DQL verification (Magaki sign-off)
        └─ Sensitive Data Center scan (optional cleanup)
```

---

## Related files

| File | Role |
| --- | --- |
| `5-dynatrace-pii-hostgroup-axa.md` | This guide |
| `5-dynatrace-pii-hostgroup-axa-question.md` | User question |
| `5-dynatrace-pii-hostgroup-axa-follow.txt` | Chat-ready copy |
| `5.sh` | Verification DQL one-liners |
| `1-dynatrace-logs-pii-filter/` | General Dynatrace PII concepts (seq 1) |

## Commands

Read-only verification DQL is in `5.sh`. Paste each line into **Logs and Events → Advanced mode** or a **Notebook**.
