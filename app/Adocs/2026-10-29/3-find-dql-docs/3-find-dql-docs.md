# Find DQL On The Dynatrace Site

```
Want to learn DQL
  open docs.dynatrace.com
  search DQL
  start on Dynatrace Query Language
  then open How to use DQL
  practice in Notebooks → Add → DQL
```

| Key point | Detail |
|---|---|
| What DQL is | Dynatrace Query Language. You use it to read logs, events, and metrics stored in Grail. |
| Start page | Dynatrace Query Language, on docs.dynatrace.com. |
| First lesson | Use DQL queries. That page explains the pipe and the first commands. |
| Where to type it | A Notebook, in a DQL section. Ctrl+Space suggests the next word. |

## Summary

On the Dynatrace docs site, search for DQL. Open the page named Dynatrace Query Language, then open How to use DQL. That is the writing lesson. The language reference is the dictionary you use after the lesson.

## Investigation

| Source | Finding |
|---|---|
| Docs hub | https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language updated January 28, 2026. |
| Getting started | Use DQL queries, updated May 4, 2026. It starts with fetch, filter, and summarize. |
| Practice | Notebooks docs: Add → DQL, shortcut Shift+D, run with Ctrl or Cmd+Enter. |

## Result

### On the website

1. Open [docs.dynatrace.com](https://docs.dynatrace.com).
2. Use the search box and type `DQL`.
3. Open **Dynatrace Query Language**. That page is the map. It links to the lesson, the reference, examples, and Learn DQL.

Direct link: https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language

| Page | When to open it |
|---|---|
| How to use DQL | First. It shows how a query is a pipeline. |
| DQL commands | When you need the list of commands, such as fetch, filter, and summarize. |
| DQL language reference | When you need the exact syntax. |
| DQL best practices | After a query works, when you want it to scan less data. |
| DQL examples for logs | When the question is about logs. |

How to use DQL: https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language/dql-guide

The lesson’s first shape is:

```
fetch logs
| filter loglevel == "ERROR"
| summarize numErr = count()
```

`fetch` loads the data. The `|` sends that table into the next command. `filter` keeps some rows. `summarize` counts what remains.

### Inside the Dynatrace product

1. Open **Notebooks**.
2. Open **Add** and choose **DQL**. The shortcut is Shift+D.
3. Type the query. Press Ctrl+Space to see command suggestions.
4. Press Run, or Ctrl+Enter on Windows and Cmd+Enter on a Mac.

If DQL is new, start with **Explore** (Logs or Events) and then choose **Show DQL**. Dynatrace writes the query for the clicks you made. That generated query is a good template.

Learn DQL is also an app in Dynatrace Hub, with interactive tutorials. The docs say a SaaS customer, a Dynatrace Community member, or a trial account can open it. The public Playground has notebooks with DQL examples too.

### A contains filter, when you need one

For this account, write `contains` with case-insensitive matching:

```
fetch logs
| filter contains(content, "ebroker-api", caseSensitive:false)
```

## Data flow map

```
docs.dynatrace.com
    -> search DQL
    -> Dynatrace Query Language
    -> How to use DQL
    -> Notebooks, Add, DQL
    -> Run
```

## Related files

| File | What it is |
|---|---|
| 3-find-dql-docs-follow.txt | The same steps, easy to copy. |
| 0-pic.md | The path. |
| 1-investigation.md | The pages that were checked. |
| 2-result.md | Where to click. |
| 3-glossary.md | The words. |
| 3.sh | Copy commands. Run them yourself. |
