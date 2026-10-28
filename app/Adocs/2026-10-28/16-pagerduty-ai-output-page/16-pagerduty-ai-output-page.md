# PagerDuty AI Output Page

```
Output page
  trained by AXA? → no
  data type → [X] Generative
  boundary → a reply with an expected shape, wording is generated
             not a score
             not a name-and-address extract
             not an open article
  samples → SRE catch-up, Scribe note, Insights sentence
  Shift → no output in this pilot
  format → [X] Text
```

| Key point | Detail |
|---|---|
| Who trains it | PagerDuty. AXA does not train this model. |
| Type | Generative. The product writes text. |
| Shape | Incident catch-up, status draft, or bridge note. |
| Format | Text only. Scribe listens to sound and writes text. |

## Summary

Tick Generative and Text. The output is a catch-up, a note, or a short answer a person still checks. Shift produces nothing in this pilot.

## Investigation

| Source | Finding |
|---|---|
| Slide | Data type is Discriminative or Generative. Generative asks whether the shape is fixed, loose, or open. Format is a separate tick row. |
| Instruction | Fill the training detail if the model is trained internally. |
| PagerDuty statement | PagerDuty does not train its models on customer data. |
| Inputs already set | SRE uses the incident and the question. Scribe uses bridge audio. Insights uses history. Shift is out. |
| Discriminative examples on the form | A score, yes/no, or a category. This product does not return those as its result. |

## Result

Paste the blocks below.

### Output

```
The model is not trained by AXA. PagerDuty provides it. PagerDuty states it does not train its models on customer data.

Data type
[ ] Discriminative
[X] Generative

Boundary of the output
Indeterminant specific structure.
The reply is about one incident or one question. A reviewer expects a catch-up, a status draft, or a bridge note. The sentences are generated.
It is not a fixed extract of names and addresses.
It is not an open article or a blog post.
It is not a score, a yes/no, or a category. Those are discriminative outputs, and this product does not return them as the result.
A person checks the text before they acknowledge, escalate, or send a status.

Samples of the output (example ids, not live tickets)

1) SRE
INC-48291 — High error rate on ebroker-api (P2)
• Status: Acknowledged
• Source on the event: Dynatrace P-88421
• Starter checks: upstream dependency, then the last deploy of this service

2) Status draft (a person sends it)
INC-48291 is acknowledged. We are checking the upstream dependency and the last deploy. Next update after those two checks.

3) Scribe
16:10 JST — Upstream timed out.
Next check — last deploy.

4) Insights, only if enabled
Among the services you can see, ebroker-api has the most P2 incidents in the last 14 days.

5) Shift
No output in this pilot.
```

### Format

```
[X] Text
[ ] Image
[ ] Video
[ ] Sound
[ ] Code
[ ] Others
```

## Data flow map

```
SRE question → text catch-up
bridge audio → text note
Insights question → one text answer
Shift → no output

person reads the text → then acts in PagerDuty
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/15-pagerduty-ai-input-page-rewrite/` | The inputs these outputs answer. |
| `Daily Files/2026-10-28/13-pagerduty-ai-security-questionnaire/` | PagerDuty does not train on customer data. |
| `16.sh` | Copy and git one-liners. Review before running. |

## Commands

See [16.sh](16.sh). Do not commit or push until you ask for that.
