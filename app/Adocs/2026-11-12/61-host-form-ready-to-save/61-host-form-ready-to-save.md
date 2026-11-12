# Host Form Ready To Save

```
query is the host CPU query
  line under 20
  below 101 is already true
delete the smartscape property row
set violating samples to 1
click Preview
  line sits under 101
  Save
wait about 3 minutes
Problems search TESTDUMMY
disable the alert
```

| Check | What you want to see |
|---|---|
| Query line 1 | `timeseries cpu = avg(dt.host.cpu.usage)` |
| Threshold | 101, and the condition says below |
| Violating samples | 1 |
| Title | `TESTDUMMY host entity` |
| `dt.source_entity` | `{dt.entity.host}` |
| After Save | A row in Problems whose title is `TESTDUMMY host entity` |

## Summary

The query, the threshold, the title, and `dt.source_entity` match the test that can open a problem. Delete the smartscape property, set violating samples to 1, click Preview, then Save. The problem appears on the Problems page. This form does not send email.

## Investigation

The three screenshots are one Edit alert form.

The query is:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

That query already returned 1 record. The line stayed under 20. Actor is shuge kui. Offset and delay are empty. Source is Davis Anomaly Detection.

The condition is static threshold. Threshold is 101. The condition is below. Alert on missing data is on. Violating samples is 3. Sliding window is 5. Dealerting samples is 5. The dialog is still open, so this version is not saved yet.

Event details:

| Key | Value on the form |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |
| `dt.smartscape_source.id` | `{dt.smartscape_source.id}` |

The query row has `dt.entity.host`. It does not have `dt.smartscape_source.id`. The yellow hint under the query is asking for a column this metric does not use. Adding that column to `by` can remove the CPU line.

Violating samples 3 means Davis waits until 3 points inside a window of 5 are below 101. The CPU line is already under 20, so 1 point is enough for this test.

## Result

Change two fields, preview, then Save.

1. In **Add details**, click the trash icon on the row `dt.smartscape_source.id`. Leave the other four rows.
2. In **Define alert condition**, set **Violating samples** to `1`. Leave the threshold at `101`. Leave the condition on **below**. Leave the sliding window at `5`. Leave dealerting samples at `5`.
3. Click **Preview**. The CPU line should sit under the line at 101. If Preview has no line, stop and send that picture. Do not Save a blank preview.
4. Click **Save**.
5. Wait about 3 minutes. Davis checks about once a minute.
6. Open **Problems** and search `TESTDUMMY`.
7. Disable the alert after the problem shows. It is a real problem on host `HOST-00026D8D201D203A`.

Leave the query as it is. Leave `{dt.entity.host}` with the braces. Leave `event.type` as `CUSTOM_ALERT`.

There is no email on this alert. The mailbox stays empty. The proof is the Problems page.

## Data flow map

```
host CPU query
  line under 20
        |
        v
threshold 101 below
  1 violating sample
  {dt.entity.host}
        |
        v
Preview shows the line under 101
        |
        v
Save
        |
        v
Davis run (about 1 minute)
        |
        v
Problems TESTDUMMY
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `61-host-form-ready-to-save.dql` | The query already on the form. |
| `0-pic.md` | Preview, then Save, then Problems. |
| `1-investigation.md` | What the three screenshots show. |
| `2-result.md` | The two edits before Save. |
| `3-glossary.md` | The words. |
| `61-host-form-ready-to-save-follow.txt` | The same steps for a phone. |
| `61.sh` | Copy commands. |

Commands: [61.sh](61.sh)
