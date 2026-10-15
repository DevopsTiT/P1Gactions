# Why 80 DQL Simple

## Decision tree

```
Goal: "Which kakakucomauto quotes timed out?"
 Is that answer in ONE log line? → no
  request line knows the channel, not the result
  error line knows the result, not the channel
  → both lines share the request ID → match them on the ID
 Splunk way: subsearch pastes the failed IDs into the search as words
 DQL cannot paste text → it joins two tables instead (lookup)
  → to join, both sides need the ID as a field → parse on both sides
```

## Short takeaway

| Question | Answer |
|---|---|
| Why not a single filter? | No single log line says "kakakucomauto" and "timed out" together. |
| Why does Splunk use a subsearch? | To get the failed IDs first and search for them as words. |
| Why does DQL use `lookup`? | DQL has no subsearch. `lookup` is its way to match one list against another. |
| Why parse the ID twice? | A join compares two fields, so both line types must have the ID as a field. |

## Summary

The DQL is built the way it is because the answer is split across two log lines. Splunk links them by pasting the failed IDs into the search as words. DQL cannot do that, so it pulls the ID out of both lines and joins them like two tables.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Request ID | The UUID that appears on every log line of one quote request. |
| Subsearch | Splunk search inside `[ ]` that runs first and pastes its result into the main search. |
| `lookup` | DQL command that matches rows from two queries on a shared field, like joining two tables. |
| `parse` | DQL command that pulls a value, such as the ID, out of the log text. |

### The story in four steps

| Step | Splunk | DQL | Why DQL is different |
|---|---|---|---|
| 1. Get failed IDs | Subsearch finds "Timeout exceeded." lines and `rex` pulls the ID | Inner query inside `lookup [ ]` with `parse` | Same idea, different command names |
| 2. Hand the IDs over | `format` turns them into `"id1" OR "id2" OR ...` | `lookup` keeps them as a small table | DQL cannot paste text into a search |
| 3. Find kakakucomauto requests | Outer search for the "Sending request..." phrase | Outer `filter contains(...)` | Same idea |
| 4. Match | Splunk looks for those ID words anywhere in the line | `parse` the ID on the request line, then join on it | A join needs a field, not raw text |

### Picture of the two approaches

```
Splunk (paste words):
 [timeout lines → IDs] → "id1 OR id2 OR id3" → search kakakucomauto lines containing those words

DQL (join tables):
 table A: kakakucomauto lines + ID
 table B: timeout IDs
 A lookup B on ID → keep rows where a match was found
```

## Result

The DQL looks longer, but it does the same three things as Splunk: get failed IDs, find kakakucomauto requests, keep the ones that match. The extra lines are the ID `parse` on the request side (needed for the join) and `filter isNotNull(err.query)` (keeps only the matched rows). The full line-by-line reasons are in today's answer 13.

## Data flow map

```
Kakaku.com quote → esbv4 "Sending request ... kakakucomauto" (ID)
                 → pc quote call → timeout → esbv4 "Timeout exceeded." (same ID)
DQL: timeout lines → ID list ┐
     kakakucomauto lines → ID ┴→ join on ID → timed-out kakakucomauto requests
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | The four steps |
| `2-result.md` | One-line conclusion |
| `3-glossary.md` | Terms |
| `14.sh` | Git one-liners (not run) |

## Commands

See `14.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/14-why-80-dql-simple
git commit -m "why 80 dql simple"
git push
```
