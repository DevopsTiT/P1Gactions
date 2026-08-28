# Today Questions

```
need every user ask from 2026-08-28?
  open this file first (master list)
  per-answer question? → <seq>-<slug>-question.md in that folder
  sidebar cloud-only topic? → pending row below (no transcript text)
  answered pack? → link to <seq>-<slug>/
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Date | 2026-08-28 |
| Questions with answer packs | 5 (seq 1–4, plus 5b host group PII) |
| Meta sync asks | 2 (dual-write audit — no new seq folder) |
| This ask | Capture all questions in both roots |
| Pending (no local transcript) | 日本失业金资格, CursorFiles经验纳入 |
| Related older content | Terraform AWS EKS — Jul 30 packs copied under seq 4 `extracted/` |

## Summary

This master list records every user question from 2026-08-28 in time order. Seq 1–4 each have a matching `-question.md` beside the answer pack. Sidebar topics without transcript text stay **pending** until source text is available.

## All questions (chronological)

| # | Time (UTC+9) | Question (verbatim or close) | Answer seq | Status |
|---|--------------|------------------------------|------------|--------|
| 1 | 09:58 | how to filter pii data in the logs of dynatrace | 1 | Answered — `1-dynatrace-logs-pii-filter` |
| 2 | 10:39 | For cursor, number folders 1 2 3 by question order; write under Files + Adocs with 0/1/2/3 docs, glossary, pic example, investigation + result in md, sh with all commands, dual-write for cloud/local/mobile (full text in transcript) | 2 | Answered — `2-pic-style-answer-workflow` |
| 3 | 10:43 | generate all file for today now | 3 | Answered — `3-generate-all-files-today` |
| 4 | 10:44 | collect all answers from agnet as well all put | 4 | Answered — `4-collect-agent-answers` |
| 5 | 10:46 | put all answers in today 2 folders | — | Meta — audit confirmed both roots already synced |
| 6 | 10:47 | put all answers in 2 folders | — | Meta — repeat audit; no copy needed |
| 7 | 10:51 | put all questions into 2 folders as well | — | In progress — this questions index |
| P1 | ~10:40 (sidebar) | 日本失业金资格 (Japan unemployment benefit eligibility) | — | Pending — cloud agent sidebar only; no Aug 28 transcript |
| P2 | ~10:45 (sidebar) | Terraform AWS EKS (deep dive / file dives) | 4 extracted | Partial — Jul 30 Q&A copied under `4-collect-agent-answers/extracted/agent-eks-blueprints/` |
| P3 | ~10:48 (sidebar) | CursorFiles经验纳入 (incorporate CursorFiles into skills) | — | Pending — Jul 9 skill work exists; no Aug 28 transcript |
| 8 | 11:24 | give me how to filter pii in dynatrace use this info (Prod-HostGroupUpdate Excel screenshot) | 5b | Answered — `5-dynatrace-pii-hostgroup-axa` |

## Per-question files

| Seq | Question file | Answer folder |
|-----|---------------|---------------|
| 1 | `1-dynatrace-logs-pii-filter/1-dynatrace-logs-pii-filter-question.md` | `1-dynatrace-logs-pii-filter/` |
| 2 | `2-pic-style-answer-workflow/2-pic-style-answer-workflow-question.md` | `2-pic-style-answer-workflow/` |
| 3 | `3-generate-all-files-today/3-generate-all-files-today-question.md` | `3-generate-all-files-today/` |
| 4 | `4-collect-agent-answers/4-collect-agent-answers-question.md` | `4-collect-agent-answers/` |
| 5b | `5-dynatrace-pii-hostgroup-axa/5-dynatrace-pii-hostgroup-axa-question.md` | `5-dynatrace-pii-hostgroup-axa/` |

## Sources scanned

| Source | What we used |
|--------|--------------|
| Transcript `59cd506d-...` | Dynatrace PII, dual-write meta asks, this ask |
| Transcript `78a23e02-...` | Numbered workflow, generate all, collect agent |
| Answer packs seq 1–4 | Investigation sections for question wording |
| Sidebar screenshot | Pending topics: 日本失业金, Terraform AWS EKS, CursorFiles经验纳入 |

## Data flow map

```
User ask (chat / cloud sidebar)
  → agent transcript (when local)
  → answer pack seq N (CursorFiles + Adocs)
  → question file seq N-question.md (this pass)
  → master 0-questions-today.md
  → 0-index-today.md (questions column)
```

## Related files

| File | Role |
|------|------|
| `0-index-today.md` | Day index with questions column |
| `0-questions-today.md` | This master list |
| `1-dynatrace-logs-pii-filter-question.md` | Seq 1 question |
| `2-pic-style-answer-workflow-question.md` | Seq 2 question |
| `3-generate-all-files-today-question.md` | Seq 3 question |
| `4-collect-agent-answers-question.md` | Seq 4 question |
| `5-dynatrace-pii-hostgroup-axa-question.md` | Seq 5b question |

## Paths

| Root | Path |
|------|------|
| CursorFiles | `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-28/` |
| Adocs | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/` |
