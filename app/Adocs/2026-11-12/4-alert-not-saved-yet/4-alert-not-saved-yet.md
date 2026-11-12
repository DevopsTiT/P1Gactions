# Alert Is Not Saved Yet

```
Is the alert set up?
  Edit alert is still open
    Save is still on the screen
    the alert is a draft
  the Notebook shows 144 records
    that is a search result
    a search does not save an alert
  the draft query matches every line in the log group
    START, END, and REPORT are included
    add loglevel == "ERROR" before Save
```

| What you see | What it means |
|---|---|
| The title Edit alert | You are still in the editor. |
| The Save button | The draft is not confirmed. |
| Set scope marked Completed | The query is filled in. |
| 144 records in the Notebook | The query finds lines. It does not create an alert. |

## Summary

The alert is not set up. The editor is still open, and the Notebook is only a search. After you add an ERROR filter, press Save. The alert exists when this editor closes and the alert appears in the custom alert list.

## Investigation

| Item on the screen | Value |
|---|---|
| Screen | Edit alert, Advanced tab. |
| Data type | Records. This fires on matching log lines. |
| Query | `fetch logs` where `aws.log.group` contains `/aws/lambda/light-digital-api-dev-confirm-e-signature`. |
| Missing filter | No `loglevel == "ERROR"`. |
| Identity field | `aws.log.group`. |
| Task execution | Marked completed. Actor is filled in. |
| Notebook | 144 records from 07:16 to 09:16 on 2026-11-12. |
| Lines in those 144 | INFO lines such as START, END, and REPORT, plus ERROR lines that say Failed to handle. |

The `contains` in the draft has no `caseSensitive:false`.

## Result

Add this line to the query before you press Save.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
```

Then press Save.

| After Save | What you should see |
|---|---|
| The editor closes | The draft was stored. |
| Custom alerts list | A row for this alert. |
| Problems | A problem only after a new ERROR line arrives while the alert is on. |

Records mode uses the query as the condition. Every line the query returns can raise an alert. The current query returns the healthy START and END lines too, so Save on the current text would watch all 144 kinds of lines.

## Data flow map

```
Edit alert window still open
        |
        v
Save not pressed
        |
        v
no alert is stored

Notebook 144 records
        |
        v
proof the log group has lines
        |
        v
not an alert
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Why this is still a draft. |
| `1-investigation.md` | What the two screens show. |
| `2-result.md` | The line to add before Save. |
| `3-glossary.md` | The words. |
| `4-alert-not-saved-yet-follow.txt` | The same answer for a phone. |
| `4.sh` | Copy commands. |

Commands: [4.sh](4.sh)
