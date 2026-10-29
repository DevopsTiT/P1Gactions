# Generative Questions Explained

```
Someone types @PagerDuty in Teams
  catch me up? → write the incident story and the first checks
  likely root causes? → write angles to verify, still a draft
  draft a status? → write the internal update, a person sends it
  wrap me up? → write the bridge timeline as text
  which service has the most P2s? → one sentence from history, only if Insights is on
```

| Question | What they want back |
|---|---|
| Catch me up on INC-48291 | The story of this one incident, plus where to look first. |
| What are some likely root causes? | A short list of checks. The cause is still a draft. |
| Draft an internal status update | Wording for stakeholders. A person sends it. |
| Wrap me up, including Scribe notes | The bridge turned into a timed note. |
| Which service has the most P2 incidents in 14 days? | One sentence from incidents this person can already see. |

## Summary

These are generative because the assistant writes sentences. The person already knows the kind of note they want. The wording changes with the incident. A score, a yes or no, or a category would be the other data type on the form, Discriminative. This slide does not ask for that.

## Investigation

| Source | Finding |
|---|---|
| Slide | Type of Insight Needed (Output). Data type is ticked Generative. Format is ticked Text. |
| Prompts on the slide | Five asks, all starting from one sample incident, INC-48291. |
| Boundary on the form | Fixed structure, field or domain specific structure such as RAG, or open content such as a blog post. |
| Sample ids | INC-48291, P-88421, and INC-47102 are the example story on the slide. They are not live tickets. |

## Result

Read each prompt as a request for a known kind of note. The assistant fills in the sentences. Primary still checks them before acknowledge, escalate, resolve, or publish.

### 1. Catch me up on INC-48291

Primary, or someone who just joined the channel, does not want to open every tool yet. The question means: tell me what this incident already says.

The sample answer is a catch-up. It names the service ebroker-api, priority P2, that Primary acknowledged it at 16:05 JST, and that the event carries Dynatrace problem P-88421. It also points at one older incident, INC-47102, as a related agrex dependency recovery. Then it gives three starter checks: the agrex and zipcode dependency, a recent deploy or config change, and whether the log line is the specific phrase “Address conversion failed…” or a broad 5xx.

That is generative. The shape is a briefing. The sentences are written for this incident. The person still opens Dynatrace on P-88421 and compares the note with the detector.

### 2. What are some likely root causes?

This is the careful question. Primary is not asking the assistant to close the incident. Primary is asking for angles to verify.

The sample lists four angles for INC-48291:

| Angle | What Primary would go and check |
|---|---|
| Agrex zipcode dependency | Latency, 5xx, or a timeout on that dependency. |
| Zip input volume | Whether the volume of zip lookups is unusual. |
| Address-service config | Whether the ebroker address-service config or URL changed after a deploy. |
| Network path | The path to the intraxa host. |

The form’s own rule on the architecture slide still applies. “Causes” is a draft. Primary replaces that draft with confirmed evidence before the PIR is published. So this question is allowed. Treating the list as the confirmed cause is not.

### 3. Draft an internal status update for INC-48291

Primary needs words for people who are not on the bridge. The question asks for a draft, not for the tool to send it.

The sample has a title, an impact line, a start time, the status “Investigating”, the evidence so far, a next update in 30 minutes, and the owner. The evidence line points back at Dynatrace P-88421 and the address-conversion log phrase. “Investigating” means the cause is not confirmed yet.

A person reads that draft and sends it. The assistant only writes it.

### 4. Wrap me up, including Scribe notes

Primary wants one note that includes what was said on the bridge. The input to Scribe was the Teams audio. The output is text.

The sample timeline is:

| Time | What the note keeps |
|---|---|
| 16:08 JST | Bridge opened. The incident is acknowledged. |
| 16:10 JST | Upstream timed out. |
| 16:12 JST | Next check is the last deploy of ebroker-api. |
| 16:14 JST | Decision: finish those two checks before the next status. |

“Wrap me up” means: combine the catch-up with that timeline. A name spoken on the bridge can show up in these lines. That name is the red-dot personal information.

### 5. Which service has the most P2 incidents in the last 14 days?

This is the Insights question. It is one question about history, not a new incident briefing. The sample answer is one sentence: among the services this user can see, ebroker-api has the most P2 incidents in that window.

Ask this only if the Insights agent is enabled. The weekly notice is out of the pilot. The assistant answers from PagerDuty incidents the user can already see.

## What the form means by Generative

The left side of the slide asks where the boundary of that writing sits.

| Boundary on the form | How these five questions sit there |
|---|---|
| Fixed structure | A fixed extract, such as pulling a name and an address out of a paragraph. These questions do not ask for that. The catch-up has headings, and the sentences under them change with the incident. |
| Field or domain specific structure | This is the match. The reader expects a catch-up, a cause list to verify, a status draft, a bridge note, or one history sentence. The form’s example of this boundary is RAG. Here the grounding text is the incident, the runbook, the Teams question, and, for Scribe, the bridge audio. |
| Open content | A new article or blog post, with no expected shape. These questions ask for a briefing about one incident or one count. |

## Data flow map

```
Primary types @PagerDuty in Teams
    -> Catch me up        -> catch-up text
    -> likely causes?     -> angles to verify (draft)
    -> draft a status     -> status text, a person sends it
    -> wrap me up         -> bridge audio becomes a timed note
    -> most P2s in 14 days -> one Insights sentence, if enabled
    -> Primary checks the text
    -> then acknowledges, escalates, resolves, or publishes the PIR
```

## Related files

| File | What it is |
|---|---|
| 1-generative-questions-explained-follow.txt | The same explanation, easy to copy. |
| 0-pic.md | Which question leads to which note. |
| 1-investigation.md | What was on the slide. |
| 2-result.md | How to read the five prompts. |
| 3-glossary.md | The words on the form. |
| 1.sh | Copy commands. Run them yourself. |
