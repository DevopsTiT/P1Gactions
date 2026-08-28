# Agent / Assistant Excerpts From This Chat

Source transcript: `/Users/k/.cursor/projects/Users-k-Codes/agent-transcripts/78a23e02-be0a-46eb-b704-2f1d1eb5f71e/78a23e02-be0a-46eb-b704-2f1d1eb5f71e.jsonl`

## Excerpt 1

```
**EKS Blueprints is a cookbook of complete EKS recipes in Terraform — not a module you call with `source =`.** You study or copy a `patterns/` folder, customize locals, and deploy. Full write-up: [`1-eks-blueprints-deep-dive.md`](/Users/k/Learnings/AIProject/CursorFiles/Daily%20Files/2026-07-30/1-eks-blueprints-deep-dive/1-eks-blueprints-deep-dive.md).

---

### 1. What it is and why it matters

Building EKS means more than “create a cluster”: VPC tags, IAM for pods (IRSA), CNI, ingress, autoscaling, secrets, GitOps, private networking. That integration work often takes months.

Blueprints ships **tested, opinionated patterns** so teams can get a purpose-built cluster in **days**. AWS SAs maintain it as best-effort community support (not an AWS service SLA).

| Term | Meaning |
|------|---------|
| Pattern | Full example under `patterns/` (VPC + EKS + addons + demo) |
| Supporting module | Separate Registry repo you *do* call as a module |
| Consumption | Reference the HCL, or copy-paste and edit — **not** `module "blueprints"` |

---

### 2. v5 architecture (critical)

| Old (v4) | New (v5 — this repo) |
|----------|----------------------|
| Monolithic framework with cluster modules inside Blueprints | **Patterns only** — no cluster module here |
| Blueprints wrapped everything | Cluster → [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks) |
| Addons nested inside | [`blueprints-addons`](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons) / [`blueprints-addon`](https://github.com/aws-ia/terraform-aws-eks-blueprints-addon) |
| Teams submodule | [`blueprints-teams`](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) |
| Push many Helm charts from Terraform | Prefer **GitOps pull** (Argo + GitOps Bridge) for in-cluster installs |

Why: Terraform is great for AWS (VPC/IAM), weaker at continuous K8s reconciliation and dependency ordering. Controllers/GitOps retry; Terraform stops on first failure.

---

### 3. Repo shape

```
patterns/     ← all runnable blueprints (~30)
docs/         ← getting-started, FAQ, v4→v5, pattern docs
.github/      ← plan-examples, e2e, docs publish
```

Typical pattern files:

| File | Role |
|------|------|
| `main.tf` | Providers, versions, locals (name, region, CIDR) |
| `vpc.tf` | VPC + ELB/Karpenter subnet tags |
| `eks.tf` | `terraform-aws-eks` cluster |
| `addons.tf` / `karpenter.tf` | Helm / IAM / controllers |
| `README.md` | Intent, validate, destroy notes |

---

### 4.
```

## Excerpt 2

```
Done. New numbered dual-write workflow is live, with a **pic** example as seq **2**.

### Investigation

| Check | Finding |
|-------|---------|
| `/Users/ts-shuge.kui/Work/AIProjects/Files` | Does **not** exist (no such user on this Mac) |
| Actual Files root | `/Users/k/Work/AIProjects/Files` |
| Adocs today | Seq `1` already used → this example is **seq 2** |
| Dual-write | Files + `app/Adocs` both written |
| From now on | Always-on rule added |

### Result — layout (pic example)

```
Question
  → 2-pic-style-answer-workflow/
       0-pic.md
       1-investigation.md
       2-result.md
       3-glossary.md
       2-pic-style-answer-workflow.md
       2.sh
       2-pic-style-answer-workflow-follow.txt
```

**Files:** `/Users/k/Work/AIProjects/Files/2026-08-28/2-pic-style-answer-workflow/`  
**Adocs:** `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/2-pic-style-answer-workflow/`  
**Rule:** `/Users/k/.cursor/rules/aiprojects-files-numbered-answers.mdc`

### From now on (every question)

| Rule | Detail |
|------|--------|
| Folder seq | `1`, `2`, `3`… under today’s date |
| Inner docs | `0-pic` → `1-investigation` → `2-result` → `3-glossary` |
| Always | Main `.md` + `.sh` + glossary + follow.txt |
| Dual-write | Files **and** Adocs |
| Chat | Full answer text (desktop / mobile / cloud) — not path-only |
| Git | Commands in `.sh`; no push unless you say so |

### Pic flow

```
Ask → next seq folder → 0/1/2/3 + main md + sh + glossary
  → copy to Adocs
  → full text in chat
```

Path note: prompts that say `ts-shuge.kui` map to `/Users/k/Work/AIProjects/Files` on this machine.
```

## Excerpt 3

```
All of today’s packs are generated on **both** roots.

### Investigation

| Gap | Fix |
|-----|-----|
| Files missing seq 1 | Synced Dynatrace pack from Adocs |
| Seq 1 missing `0/1/2/3` | Added pic, investigation, result, glossary |
| Seq 2 | Already complete |
| No day index | Added `0-index-today.md` |
| This ask | Created **seq 3** |

### Result — 2026-08-28

| Seq | Folder | Topic |
|-----|--------|-------|
| 1 | `1-dynatrace-logs-pii-filter` | Dynatrace log PII filtering |
| 2 | `2-pic-style-answer-workflow` | Pic-style numbered workflow |
| 3 | `3-generate-all-files-today` | Complete/backfill today |

Each folder has: `0-pic.md`, `1-investigation.md`, `2-result.md`, `3-glossary.md`, main `.md`, `.sh`, `*-follow.txt`.

**Files:** `/Users/k/Work/AIProjects/Files/2026-08-28/`  
**Adocs:** `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/`  
**Index:** `0-index-today.md` in both

Next question today → **seq 4**.
```

