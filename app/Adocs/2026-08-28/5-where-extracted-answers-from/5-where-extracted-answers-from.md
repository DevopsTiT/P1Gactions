# Where Extracted Answers Come From

```
seeing extracted/4-nvidia… 4-sso-okta… 4-docs-files…?
  those are COPIES, not new answers from today
  original? → Daily Files 2026-07-30/4-eks-blueprints-each-file-deep-dive/
  why in today's tree? → seq 4 "collect agent answers" copied them under extracted/
  source repo studied? → terraform-aws-eks-blueprints patterns/ docs/ .github/
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What you opened | Copies inside `4-collect-agent-answers/extracted/agent-eks-blueprints/...` |
| Original write date | **2026-07-30** (this same EKS Blueprints chat lineage) |
| Original folder | `CursorFiles/Daily Files/2026-07-30/4-eks-blueprints-each-file-deep-dive/` |
| Why prefix `4-` | That pack was **seq 4 on Jul 30**, not “today’s seq 4 file names” |
| Upstream content | File-by-file deep dive of `terraform-aws-eks-blueprints-main` |

## Summary

The files in your screenshot are **archived copies** of an earlier deep dive. Today’s seq 4 only **collected** them so everything sits in one place. They were not regenerated from scratch this morning.

## Investigation

| Check | Finding |
|-------|---------|
| Screenshot path shape | `extracted/` + many `4-*.md` + `today-seq-1-3` sibling |
| Match on disk | `.../4-collect-agent-answers/extracted/agent-eks-blueprints/4-eks-blueprints-each-file-deep-dive/` |
| `patterns/4-*.md` | One md per EKS Blueprints **pattern** (karpenter, sso-okta, vpc-lattice, …) |
| `4-root-files.md` / `4-docs-files.md` / `4-github-files.md` | Repo root, docs/, .github/ file dives |
| Who wrote originals | Main agent + explore subagents during “explain each file deep dive” |
| Git green **U** | Untracked in whatever repo/workspace root you have open (often P1Gactions) — copies landed under Adocs or a watched path |

## Result — provenance map

```
terraform-aws-eks-blueprints-main/
  patterns/* , docs/ , .github/ , README…
        │
        │  (Jul 30 chat: "explain each file deep dive in each md")
        ▼
CursorFiles/Daily Files/2026-07-30/
  4-eks-blueprints-each-file-deep-dive/
    4-root-files.md
    4-docs-files.md
    4-github-files.md
    4-eks-blueprints-each-file-deep-dive.md
    4.sh
    patterns/4-karpenter.md
    patterns/4-sso-okta.md
    patterns/4-nvidia-gpu-efa.md
    ... (30 pattern mds)
        │
        │  (Aug 28: "collect all answers from agent as well all put")
        ▼
Files + Adocs /2026-08-28/4-collect-agent-answers/
  extracted/agent-eks-blueprints/4-eks-blueprints-each-file-deep-dive/   ← YOU ARE HERE
  extracted/today-seq-1-3/   ← today's Dynatrace / pic / generate-all
```

### What each group is

| Files you see | Meaning |
|---------------|---------|
| `4-karpenter.md`, `4-sso-okta.md`, `4-vpc-lattice.md`, … | Deep dive of **one pattern folder** under `patterns/` |
| `4-root-files.md` | Root repo files (README, LICENSE, mkdocs, …) |
| `4-docs-files.md` | Everything under `docs/` |
| `4-github-files.md` | Everything under `.github/` |
| `4.sh` | Commands from that Jul 30 pack |
| `today-seq-1-3/` (sibling) | **Different** source: today’s seq 1–3 answers |

### Full original path

`/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-07-30/4-eks-blueprints-each-file-deep-dive/`

### Copy path (what the sidebar shows)

`/Users/k/Work/AIProjects/Files/2026-08-28/4-collect-agent-answers/extracted/agent-eks-blueprints/4-eks-blueprints-each-file-deep-dive/`

(and the Adocs mirror under `P1Gactions/app/Adocs/2026-08-28/4-collect-agent-answers/...`)

## Data flow map

```
EKS Blueprints GitHub repo files
  → Jul 30 agent file-by-file mds (seq 4 that day)
  → Aug 28 collect job copies into extracted/
  → Cursor sidebar shows untracked copies
```

## Related files

| File | Role |
|------|------|
| [0-pic.md](0-pic.md) | Pic provenance flow |
| [1-investigation.md](1-investigation.md) | How we traced it |
| [2-result.md](2-result.md) | Exact paths |
| [3-glossary.md](3-glossary.md) | Terms |
| [5.sh](5.sh) | ls/diff commands |

## Commands

See [5.sh](5.sh).
