# Pic Style Answer Workflow

```
need answers that work on desktop + mobile + cloud chat?
  write under Files/<date>/<seq>-<slug>/  AND  app/Adocs/<date>/<seq>-<slug>/
  folder seq? → 1, 2, 3… per question that day
  inside folder docs? → 0-pic → 1-investigation → 2-result → 3-glossary
  commands? → <seq>.sh (one command per line, everything included)
  always? → main md + glossary + follow.txt for mobile copy
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Primary path | `/Users/k/Work/AIProjects/Files/<YYYY-MM-DD>/<seq>-<slug>/` |
| Mirror path | `P1Gactions/app/Adocs/<YYYY-MM-DD>/<seq>-<slug>/` |
| Question folders | Numbered `1`, `2`, `3`… by ask order that day |
| Inner docs | `0-pic`, `1-investigation`, `2-result`, `3-glossary` |
| This example | Seq **2** · slug **pic-style-answer-workflow** · topic = pic-style workflow |

## Summary

This folder is the live example of the new Cursor answer layout. Pic-style means plain arrow/text flows first. Every question gets investigation + result in the main md, a glossary companion, a command shell file, and a dual write for cloud/local/mobile follow.

## Investigation

| Check | Finding |
|-------|---------|
| Requested path `/Users/ts-shuge.kui/Work/AIProjects/Files` | **Does not exist** on this Mac (no user `ts-shuge.kui`) |
| Actual Files root | `/Users/k/Work/AIProjects/Files` (home user `k`) |
| Adocs today | Already had `1-dynatrace-logs-pii-filter` → this question is **seq 2** |
| Scope | New always-on rule + dual-write example + numbered inner docs |
| Cloud vs local | Same folder content; chat shows full text; `*-follow.txt` for mobile copy |

## Result

| Deliverable | Path |
|-------------|------|
| Main answer | `2-pic-style-answer-workflow.md` (this file) |
| Pic overview | `0-pic.md` |
| Investigation detail | `1-investigation.md` |
| Result detail | `2-result.md` |
| Glossary | `3-glossary.md` |
| Commands | `2.sh` |
| Mobile follow | `2-pic-style-answer-workflow-follow.txt` |
| Files copy | `/Users/k/Work/AIProjects/Files/2026-08-28/2-pic-style-answer-workflow/` |
| Adocs copy | `.../P1Gactions/app/Adocs/2026-08-28/2-pic-style-answer-workflow/` |
| Cursor rule | `/Users/k/.cursor/rules/aiprojects-files-numbered-answers.mdc` |

### Going-forward rule (from now on)

1. One folder per question: `<seq>-<kebab-slug>/` under **today’s date**.
2. Dual-write: **Files** + **app/Adocs** (same date/seq/slug when Adocs seq free; else next free Adocs seq with same slug note).
3. Always create: main `<seq>-<slug>.md`, `<seq>.sh`, `3-glossary.md` (or `<seq>-<slug>-glossary.md`), and preferred `*-follow.txt`.
4. Numbered companions: `0-pic.md`, `1-investigation.md`, `2-result.md`, `3-glossary.md`.
5. Main md always includes **Investigation** + **Result** sections.
6. Chat reply always includes the full useful answer (not path-only), for desktop/mobile/cloud.

## Data flow map (pic style)

```
Question asked (desktop / mobile / cloud Cursor)
  → pick next seq for today (1, 2, 3…)
  → create folder <seq>-<slug>/
  → write
       0-pic.md              (flows / decision tree)
       1-investigation.md    (what was checked)
       2-result.md           (what to do / answer)
       3-glossary.md         (terms)
       <seq>-<slug>.md       (full combined answer)
       <seq>.sh              (all commands, one per line)
       <seq>-<slug>-follow.txt
  → copy same set → app/Adocs/<date>/<seq>-<slug>/
  → show full text in chat
```

## Related files

| File | Role |
|------|------|
| [0-pic.md](0-pic.md) | Pic-style decision + flow |
| [1-investigation.md](1-investigation.md) | Path/seq investigation |
| [2-result.md](2-result.md) | Concrete layout + next steps |
| [3-glossary.md](3-glossary.md) | Terms for this workflow |
| [2.sh](2.sh) | All commands |
| [2-pic-style-answer-workflow-follow.txt](2-pic-style-answer-workflow-follow.txt) | Mobile-ready copy |

## Commands

All commands live in [2.sh](2.sh). Review before running.
