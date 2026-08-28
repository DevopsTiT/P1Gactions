# Collect Agent Answers

```
collect all agent answers + put them?
  inventory today Files/Adocs/CursorFiles
  inventory agent Daily Files from this chat (2026-07-30 EKS packs)
  copy into seq 4 extracted/
  write ALL combined + 0/1/2/3 companions + glossary
  dual-write Files + Adocs (+ CursorFiles)
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Seq | **4** · `collect-agent-answers` |
| Today packs collected | seq 1, 2, 3 |
| Agent packs collected | 1-eks-blueprints-deep-dive, 3-eks-blueprints-patterns-file-dive, 3-eks-blueprints-root-docs-github, 4-eks-blueprints-each-file-deep-dive |
| Combined dump | `ALL-collected-answers.md` |
| Dual-write | Files + Adocs + CursorFiles |

## Summary

All of today’s answers plus the EKS Blueprints agent deep-dive packs from this conversation lineage are copied under `extracted/` and indexed here for desktop, mobile, and cloud follow.

## Investigation

| Source | Finding |
|--------|---------|
| Files/Adocs 2026-08-28 | Had seq 1–3 + day index |
| CursorFiles today | Only seq 1 fully present before this collect |
| Agent Daily Files 2026-07-30 | Found EKS Blueprints agent packs from this chat |
| Transcript `78a23e02-...` | Parent chat for Terraform AWS EKS blueprints / today’s workflow |
| Subagent answers | Pattern/root/github file dives lived under Jul 30 Daily Files |

## Result

| Location | Path |
|----------|------|
| Files | `/Users/k/Work/AIProjects/Files/2026-08-28/4-collect-agent-answers/` |
| Adocs | `.../app/Adocs/2026-08-28/4-collect-agent-answers/` |
| CursorFiles | `.../Daily Files/2026-08-28/4-collect-agent-answers/` |
| Today copies | `extracted/today-seq-1-3/` |
| Agent copies | `extracted/agent-eks-blueprints/` |
| Combined | `ALL-collected-answers.md` |

# Collected Agent And Today Answers

This file indexes everything collected into this folder.

## Today seq 1–3 (copied)

- `extracted/today-seq-1-3/1-dynatrace-logs-pii-filter/`
- `extracted/today-seq-1-3/2-pic-style-answer-workflow/`
- `extracted/today-seq-1-3/3-generate-all-files-today/`

## Agent EKS Blueprints packs (from 2026-07-30 agents)

- `extracted/agent-eks-blueprints/1-eks-blueprints-deep-dive/`
- `extracted/agent-eks-blueprints/3-eks-blueprints-patterns-file-dive/`
- `extracted/agent-eks-blueprints/3-eks-blueprints-root-docs-github/`
- `extracted/agent-eks-blueprints/4-eks-blueprints-each-file-deep-dive/`

## Transcript excerpts

- `extracted/transcript-excerpts.md`


## Data flow map

```
Agent answers (Jul 30 Daily Files)
  + Today seq 1/2/3 (Files/Adocs)
  + Transcript excerpts
      → seq4 extracted/
      → ALL-collected-answers.md
      → dual-write Files + Adocs + CursorFiles
```

## Related files

| File | Role |
|------|------|
| [0-pic.md](0-pic.md) | Pic overview |
| [1-investigation.md](1-investigation.md) | Sources checked |
| [2-result.md](2-result.md) | What was put where |
| [3-glossary.md](3-glossary.md) | Terms |
| [ALL-collected-answers.md](ALL-collected-answers.md) | Combined content |
| [4.sh](4.sh) | Verify commands |
| [4-collect-agent-answers-follow.txt](4-collect-agent-answers-follow.txt) | Mobile follow |

## Commands

See [4.sh](4.sh).
