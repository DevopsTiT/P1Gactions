# Splunk 1 To 85 Glossary

| Splunk command | What it means |
|---|---|
| `search` | Filters rows by text or by field values. |
| `where` | Filters rows with a true or false expression. |
| `eval` | Creates or changes a field. |
| `rex` | Pulls a value out of text with a regular expression. |
| `rex max_match=0` | Keeps every match, so the field becomes a list. |
| `spath` | Reads JSON into fields. |
| `replace()` | Swaps text that matches a regular expression. |
| `match()` | Case-sensitive regular expression test. |
| `regex` | Keeps rows where a case-sensitive regular expression matches. |
| `CASE()` | Makes one search word case-sensitive. |
| `mvappend()` | Builds a list from several values. |
| `mvjoin()` | Glues a list into one string. |
| `strftime()` | Turns a time into readable text. |
| `strptime()` | Turns date text into a time value. |
| `relative_time()` | Moves a time forward or back, such as plus 30 days. |
| `substr()` | Cuts part of a string. Counts from 1. |
| `dedup` | Keeps the first row for each value. |
| `stats` | Groups rows and calculates counts, sums or value lists. |
| `values()` | Lists the unique values in a group. |
| `timechart` | Counts or sums per time bucket. |
| `bin` | Rounds time into buckets. |
| `table` | Shows only the listed columns. |
| `fields` | Keeps or removes fields. |
| `sort` | Orders rows. A minus sign means largest first. |
| `metadata` | Reads Splunk's summary list of hosts or sourcetypes. |
| `makeresults` | Creates one empty row. |
| `lookup` | Reads a stored CSV table. |
| Subsearch `[ ]` | Runs first and pastes its result into the outer search. |
| `format` | Turns subsearch rows into an OR search string. |
| `earliest` | Start of the time range. |
