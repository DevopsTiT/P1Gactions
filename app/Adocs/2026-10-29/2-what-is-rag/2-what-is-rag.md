# What Is RAG

```
Form says field or domain specific structure, example RAG
  what does the person want? → a note with a known shape
  where do the facts come from? → material already retrieved
  for this pilot → the open incident, the linked runbook, the Teams question
  Scribe → the bridge audio, then a text note
  causes → still a draft until Primary confirms them
```

| Key point | Detail |
|---|---|
| The letters | RAG means retrieval-augmented generation. |
| Retrieval | Find the relevant material first. |
| Generation | Write the sentences from that material. |
| Why the form uses it | It is their example of a briefing with an expected shape, grounded on source text. |

## Summary

RAG is two steps. First the system retrieves the pieces that matter. Then the model writes the answer from those pieces. On this slide it is the example for “field or domain specific structure.” For the war-room questions, the pieces are the open PagerDuty incident, the runbook linked on that service, and the question Primary typed. Scribe adds the bridge audio and still returns text.

## Investigation

| Source | Finding |
|---|---|
| Output slide | Generative is ticked. The boundary choices include field or domain specific structure, with RAG as the example. |
| The five prompts | Catch me up, likely causes, status draft, wrap me up, and one Insights count. |
| What this pilot retrieves | The incident fields, the linked runbook, the Teams question, and bridge audio for Scribe. The full log store is not connected. |

## Result

When the form says RAG, read it as: the reply is written, and it is written from retrieved material about this incident. It is a briefing. Primary still checks it.

### The two steps

Retrieval means “go get the source.” Generation means “write the note.”

A plain way to picture it:

```
question
    -> retrieve the incident, the runbook, and the question
    -> write the catch-up, the status draft, or the bridge note
    -> Primary reads it and checks the detector
```

If the retrieval step is skipped, the model is only guessing from general training. RAG adds the retrieved pages so the sentences stay on this incident.

### How that maps to the five questions

| Question | What gets retrieved | What gets written |
|---|---|---|
| Catch me up on INC-48291 | Incident id, title, priority, status, service, timeline, the Dynatrace id on the event, the linked runbook. | A catch-up and the starter checks. |
| What are some likely root causes? | The same incident, plus the checks the runbook or the pasted line suggests. | Angles to verify. The cause stays a draft. |
| Draft an internal status update | The incident facts and the evidence already named. | A status draft. A person sends it. |
| Wrap me up, including Scribe notes | The bridge audio, plus the incident. | A timed text note. |
| Which service has the most P2 incidents in 14 days? | Past incidents this user can see. Only if Insights is enabled. | One sentence. |

### Where it sits on the form

| Boundary | What it means here |
|---|---|
| Fixed structure | The same fields every time, such as a name and an address pulled from a paragraph. |
| Field or domain specific structure | The reader expects a catch-up, a verify-list, a status draft, or a bridge note. RAG is the form’s example of this row. |
| Open content | A new article with no expected shape. |

The five questions sit on the middle row. The headings stay familiar. The sentences change with the incident.

### What to say in the meeting

The assistant writes from the incident and the runbook already linked to it. It does not receive the full Splunk or Dynatrace store. Primary compares the note with the detector before acknowledge, escalate, resolve, or PIR publish. Sample ids on the slide, including INC-48291 and P-88421, are examples.

## Data flow map

```
Teams question
    -> retrieve incident + runbook
    -> write the note
    -> text back in Teams
    -> Primary checks Dynatrace or the bridge note
    -> then acts
```

## Related files

| File | What it is |
|---|---|
| 2-what-is-rag-follow.txt | The same explanation, easy to copy. |
| 0-pic.md | The two steps. |
| 1-investigation.md | Where the word appears. |
| 2-result.md | What to say. |
| 3-glossary.md | The words. |
| 2.sh | Copy commands. Run them yourself. |
