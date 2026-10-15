# Splunk SPL To DQL Logic

## Decision tree

```
Splunk query in front of you
 1 time range (picker, earliest=)        → fetch logs, from:now()-24h
 2 where (index / sourcetype / host)      → filter on src / log.source / host.name
      exact value     → ==
      prefix* value   → startsWith
      *middle* value  → contains
 3 text terms
      bare word ERROR        → matchesPhrase(content, "ERROR")
      "quoted phrase"        → contains(content, "...", caseSensitive:false)
      CASE() / match / regex → contains(...) case-sensitive, or matchesValue / parse
      AND / OR / NOT         → and / or / not (keep the brackets)
 4 field=value on a field Splunk auto-extracted
      → parse it out first, then ==
 5 rex / spath / eval      → parse (DPL) / parse "JSON:j" / fieldsAdd
 6 stats / timechart / table / sort / head / dedup
      → summarize / makeTimeseries / fields / sort / limit / dedup
 7 [subsearch] / join / lookup / metadata / makeresults
      → lookup [ ] / join / load / max(timestamp) / data
 8 test → data record(...) with match + non-match rows → then compare counts with Splunk
 0 rows? → run only lines 1 and 2 → 0 = wrong source or not onboarded | rows = text filter wrong
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the core idea? | Split the Splunk query into jobs (time, where, text, extract, shape, join), then translate each job into its DQL line. |
| Biggest difference? | Splunk ignores case and auto-extracts `key=value` fields. DQL does neither unless you ask. |
| What replaces `index`? | A source filter, usually `src = lower(coalesce(k8s.pod.name, host.name))` then `startsWith`. |
| What replaces `rex`? | `parse` with a DPL pattern. |
| What replaces a subsearch? | `lookup [ inner query ]` joined on a shared field. |
| How do I know it is right? | Test with the `data` command, then compare row counts with Splunk for the same time window. |

## Summary

Do not translate word by word. Read the Splunk query once, label each part by its job, then write one DQL line per job in the fixed order: fetch, source, text, extract, shape, sort and fields. Most mistakes come from three Splunk habits that DQL does not copy: case-insensitive matching, automatic field extraction, and pasting subsearch results as text.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| SPL | Splunk Processing Language, the Splunk query language. |
| DQL | Dynatrace Query Language. Each `\|` line passes rows to the next. |
| `_raw` and `content` | The full log line. `_raw` in Splunk, `content` in Dynatrace. |
| Auto-extraction | Splunk turns `key=value` text into fields by itself. Dynatrace does not. |
| DPL | Dynatrace Pattern Language, used inside `parse`. It replaces regex. |
| Subsearch | A Splunk query in `[ ]` whose results are pasted into the outer query. |

### Step 1: label each part of the Splunk query

Take this Splunk query (#2):

```
index="pc2-batch" host="pc*" "Exception occured for job" "during afterBind_Adj process"
```

| Splunk part | Job |
|---|---|
| (time picker) | Time |
| `index="pc2-batch"` | Where |
| `host="pc*"` | Where |
| `"Exception occured for job"` | Text |
| `"during afterBind_Adj process"` | Text (joined with an implied AND) |

Splunk puts an invisible AND between terms. In DQL write `and`, or write a new `filter` line.

### Step 2: time

| Splunk | DQL |
|---|---|
| Time picker "Last 24 hours" | `fetch logs, from:now()-24h` |
| `earliest=-1d` | `fetch logs, from:now()-1d` |
| `earliest=-7d latest=-1d` | `fetch logs, from:now()-7d, to:now()-1d` |
| `earliest=@d` (since midnight) | `fetch logs, from:@d` |

### Step 3: where the logs come from

Splunk `index` has no direct twin. Dynatrace stores logs with Kubernetes and host fields instead.

| Splunk | DQL | When |
|---|---|---|
| `index=esbv4` | `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` then `filter startsWith(src, "esbv4")` | App runs in Kubernetes, pods are named after the app. |
| `host="exact-name"` | `filter lower(host.name) == "exact-name"` | Exact host. `lower` copies Splunk's ignore-case. |
| `host="pc*"` | `filter startsWith(host.name, "pc")` | Wildcard only at the end. |
| `host="*batch*"` | `filter contains(host.name, "batch")` | Wildcard on both sides. |
| `host=a OR host=b` | `filter in(host.name, array("a", "b"))` | A short exact list. |
| `sourcetype=x` | `filter log.source == "x"` or `contains(log.source, "x")` | Check first which field holds the value. |

If you do not know which field holds the name, run a check query first:

```
fetch logs, from:now()-1h
| filter contains(host.name, "pc2") or contains(k8s.pod.name, "pc2") or contains(log.source, "pc2")
| summarize n = count(), by:{host.name, k8s.pod.name, log.source}
```

### Step 4: text terms

| Splunk | DQL | Why |
|---|---|---|
| `ERROR` (bare word) | `matchesPhrase(content, "ERROR")` | Whole word, ignores case, like Splunk. |
| `"Timeout exceeded"` (quoted) | `contains(content, "Timeout exceeded", caseSensitive:false)` | Exact phrase anywhere, ignoring case. |
| `"*Exception*"` | `contains(content, "Exception", caseSensitive:false)` | Drop the stars; `contains` already means "anywhere". |
| `CASE("FAIL")` | `contains(content, "FAIL")` | Case must match, so no `caseSensitive:false`. |
| `\| where match(_raw, "abc")` | `contains(content, "abc")` | Plain text inside the regex. |
| `\| regex _raw="a.*b"` | `matchesValue(content, "*a*b*")` or a `parse` pattern | Real regex needs a pattern, not `contains`. |
| `A B` | `filter A and B` | Implied AND. |
| `A OR B` | `filter A or B` | Same. |
| `NOT A` | `filter not A` | Same. |
| `(A OR B) NOT C` | `filter (A or B) and not C` | Keep the brackets. |

### Step 5: fields Splunk extracted for you

In Splunk, `errcode=E01` works because Splunk saw `errcode=E01` in the text and made a field. Dynatrace has no such field, so pull it out first.

| Splunk | DQL |
|---|---|
| `errcode=E01` | `parse content, "LD 'errcode=' ALNUM:errcode"` then `filter errcode == "E01"` |
| `status>=500` | `parse content, "LD 'status=' INT:status"` then `filter status >= 500` |

Watch out: DPL captures are greedy. `ALNUM` on `errcode=E01050004` captures `E01050004`, so `== "E01"` is false. That is the correct behavior and the same as Splunk's.

### Step 6: rex, spath, eval

#### rex to parse (regex to DPL)

| Regex piece | DPL piece |
|---|---|
| `.*?` (skip anything) | `LD` |
| `literal text` | `'literal text'` |
| `\d+` | `DIGIT+` or `INT` |
| `\w+` | `WORD` or `ALNUM` |
| `\s+` | `SPACE+` |
| `[0-9a-f]{8}` | `[0-9a-f]{8}` (DPL keeps character classes) |
| `(?<name>...)` | `(...):name` or `PATTERN:name` |

Example:

```
Splunk:  | rex "errcode=(?<errcode>\w+)"
DQL:     | parse content, "LD 'errcode=' ALNUM:errcode"
```

#### rex max_match=0 (all matches)

```
| fieldsAdd lines = splitString(content, "\n")
| expand lines
| parse lines, "<pattern>"
| summarize found = collectArray(value), by:{timestamp}
```

#### spath to JSON

| Splunk | DQL |
|---|---|
| `\| spath` | `\| parse content, "JSON:j"` |
| `message.url` | `toString(j[message][url])` |
| Escaped JSON (`\"`) cleaned with `eval replace` | `fieldsAdd raw = replaceString(content, "\\\"", "\"")` then parse `raw` |

#### eval to fieldsAdd

| Splunk | DQL |
|---|---|
| `eval x=lower(host)` | `fieldsAdd x = lower(host.name)` |
| `eval x=if(c, a, b)` | `fieldsAdd x = if(c, a, else:b)` |
| `eval x=substr(s, 401, 17)` | `fieldsAdd x = substring(s, from:400, to:417)` (Splunk counts from 1, DQL from 0) |
| `eval x=coalesce(a, b)` | `fieldsAdd x = coalesce(a, b)` |
| `eval t=strftime(_time, "%F %T")` | `fieldsAdd t = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss")` |
| `eval d=round((end-now())/86400)` | `fieldsAdd d = toLong((end - now()) / 1d)` |

### Step 7: shape the result

| Splunk | DQL |
|---|---|
| `stats count` | `summarize count()` |
| `stats count by host` | `summarize count = count(), by:{host.name}` |
| `stats values(x) by y` | `summarize vals = collectDistinct(x), by:{y}` |
| `stats dc(x)` | `summarize countDistinctExact(x)` |
| `stats latest(_time)` | `summarize max(timestamp)` |
| `stats avg(d) max(d)` | `summarize avg(d), max(d)` |
| `timechart span=1h count by app` | `makeTimeseries count(), interval:1h, by:{app}` |
| `where count > 1` (after stats) | `filter count > 1` |
| `table a b c` | `fields a, b, c` |
| `fields - x` | `fieldsRemove x` |
| `rename a AS b` | `fieldsRename b = a` |
| `sort - count` | `sort count desc` |
| `head 5` | `limit 5` |
| `dedup x` | `dedup x` |

### Step 8: subsearch, lookup, metadata, makeresults

| Splunk | DQL |
|---|---|
| `... [search ... \| fields query \| format]` | `lookup [ inner query \| fields query ], sourceField:query, lookupField:query, prefix:"err."` then `filter isNotNull(err.query)` |
| `join type=inner id [search ...]` | `join [ inner query ], on:{id}` |
| `lookup mytable key OUTPUT val` | `lookup [ load "/lookups/mytable" ], sourceField:key, lookupField:key` |
| `\| metadata type=hosts` | `summarize last = max(timestamp), by:{host.name}` |
| `\| makeresults \| eval ...` | `data record(...)` |

Why the subsearch becomes a lookup: Splunk's `format` pastes the inner results as words into the outer search, so the ID can match anywhere in the text. DQL cannot paste text into another query, so pull the ID out on both sides with `parse` and join on it.

### Worked example: #78 subsearch

Splunk:

```
index=esbv4 "Sending request to /esb/ebroker/inswebauto/online/_quote"
  [search index=esbv4 "...failed: Timeout exceeded."
   | rex "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query | format]
```

| Splunk part | Job | DQL line |
|---|---|---|
| Time picker | Time | `fetch logs, from:now()-24h` |
| `index=esbv4` | Where | `fieldsAdd src = ...` and `filter startsWith(src, "esbv4")` |
| `"Sending request to ..."` | Text | `filter contains(content, "Sending request to ...", caseSensitive:false)` |
| (outer has no rex) | Extract | `parse content, "LD (UUID pattern):query"` added so both sides have the ID |
| `[search ... ]` | Join | `lookup [ ... ]` |
| Inner `rex ... (?<query>...)` | Extract | Inner `parse content, "LD (UUID pattern):query"` |
| `fields query \| format` | Join key | `fields query` and `sourceField:query, lookupField:query` |
| The implied AND with the subsearch | Join filter | `filter isNotNull(err.query)` |

### Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| `contains(content, "error")` for Splunk `error` | Misses `ERROR` lines | Use `matchesPhrase`, or add `caseSensitive:false`. |
| `msg_url == "payWithCreditCard_Adj"` | 0 rows, because the field holds the full URL | Use `contains` or `endsWith`. |
| Copying `"*text*"` stars into `contains` | Looks for real star characters | Drop the stars. |
| Using `errcode == "E01"` with no `parse` | The field does not exist, so 0 rows | Add the `parse` line first. |
| `substring(x, from:401, ...)` | Off by one | DQL counts from 0: use `from:400`. |
| Assuming `index` maps to a field | 0 rows or the wrong app | Run the check query to find the real field. |
| Logs not onboarded (portals-amp) | 0 rows no matter what | Confirm with the source-only lines before blaming the filters. |

## Result

The recipe in one line: **label, then translate per job, then test.**

| Step | Do |
|---|---|
| 1 | Label each Splunk part: time, where, text, extract, shape, join. |
| 2 | Write `fetch logs, from:` for the time. |
| 3 | Find the real source field with a check query, then filter on it. |
| 4 | Translate text terms with the case rules (bare word vs quoted vs CASE). |
| 5 | Add `parse` for every field Splunk auto-extracted or got from `rex` or `spath`. |
| 6 | Translate `stats`, `table`, `sort` and similar. |
| 7 | Turn subsearches into `lookup`, parsing the join key on both sides. |
| 8 | Test with `data record(...)` (answer 18), then compare counts with Splunk. |

A copy-ready template is in `19-splunk-spl-to-dql-logic-template.dql`.

## Data flow map

```
Splunk query
 → label parts (time | where | text | extract | shape | join)
 → fetch logs, from:          (time)
 → fieldsAdd src + filter     (where)
 → filter matchesPhrase / contains   (text, with case rules)
 → parse / fieldsAdd          (extract)
 → lookup [ ]                 (join, only if subsearch)
 → summarize / makeTimeseries (shape)
 → sort + fields              (output)
 → test with data record(...) → compare counts with Splunk
```

## Related files

| File | Purpose |
|---|---|
| `19-splunk-spl-to-dql-logic.md` | This answer |
| `19-splunk-spl-to-dql-logic-template.dql` | Blank DQL template in the fixed order |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Mapping tables in short |
| `2-result.md` | The 8-step recipe |
| `3-glossary.md` | Terms |
| `19.sh` | Git one-liners (not run) |
| 2026-10-15 answers 15, 16, 17, 18 | Splunk line by line, DQL line by line, match examples, dummy data testing |

## Commands

See `19.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/19-splunk-spl-to-dql-logic
git commit -m "splunk spl to dql logic"
git push
```
