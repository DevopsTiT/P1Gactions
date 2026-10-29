# Splunk Incident Helper Dashboard

```
Want a page like EIP/DIS Incident Helper
  one time range for the whole page → Last 15 minutes
  one box → one search → one picture
    a count → Single value
    a letter such as A → Single value
    host and status → Table
  color → set on that box
    failure box stays red
    success box stays green
  box says No results found → that search matched zero events
    open the search in Search
    widen the time
    check the host filter
```

| Key point | Detail |
|---|---|
| Product | Splunk. The page title is EIP/DIS Incident Helper Dashboard. |
| Shared control | Search by Time is Last 15 minutes. Auto-refresh is on. |
| One box | One search and one picture. |
| Top row | Four counts: API gateway failure, API gateway success, IS success, IS failure. |
| Middle row | Failed-count and ND Mode for DCI Kappa, then the same pair for DCI English. |
| Bottom row | Mediator host table and integration host table. |
| Empty box | The search returned no events. The box itself is still there. |

## Summary

Build this page in Splunk Dashboard Studio. Add one time-range input, then add one panel per box. A count or a mode letter uses a Single value chart. A host list uses a Table. Paint failure panels red and success panels green, including when the number is 0. The searches behind this live page are inside each panel. The examples below follow the titles on the screen. Replace the index and sourcetype with the ones those panels already use.

## Investigation

| Source | Finding |
|---|---|
| Page title | EIP/DIS INCIDENT HELPER DASHBOARD. |
| Time | Last 15 minutes. Auto-refresh is shown. |
| APIGateway FAILURE | 538, red. |
| APIGateway SUCCESS | 19,187, green. |
| IS Success | 0, green. |
| IS Failure | 0, red. |
| EIP 10/15 DCI (Kappa) | API GW WPLALJ2BC and WPLALJ2BB failed count. No results found. |
| ND Mode in DCI (Kappa) | Letter A. Caption EIP ND Mode. |
| EIP 12/15 DCI (English) | API GW WPLALJ2CO and WPLALJ2BF failed count. 536, with the word FAILURE, red. |
| ND Mode in DCI (English) | Letter A. Caption EIP ND Mode. |
| DCI_Mediator_Servers, left | No results found. |
| DCI_Mediator_Servers, right | WPLALJ2BF.axajp.intraxa and WPLALJ2CO.axajp.intraxa. Both MS_ResultMS_Status are EIP_UP. |
| DCI_Integration_Servers, left | No results found. |
| DCI_Integration_Servers, right | WPLALJ2C1.axajp.intraxa and WPLALJ2BO.axajp.intraxa. Both IS_ResultIS_Status are EIP_UP. |

The SPL text is not on the screenshot. Open the panel search to see the real index and fields.

## Result

### Create the page

1. In Splunk, open Dashboards.
2. Create a dashboard. Choose Dashboard Studio and Grid layout.
3. Name it EIP/DIS Incident Helper Dashboard.
4. Add an input. Choose Time range. Label it Search by Time. Default it to Last 15 minutes.
5. Turn on auto-refresh. One minute is a practical incident refresh.
6. Add the panels below. New panels use the dashboard time range, so one change of Last 15 minutes updates every box.
7. Save.

To copy this exact page, open it, choose Edit, then Clone. Change the copy. Use the original as the source of the real searches.

### Single value for a count

Add a chart. Choose Single value. Put a search that returns one number in the search box.

Failure count for the top-left box:

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE FAILURE
| stats count
```

Success count:

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE SUCCESS
| stats count
```

English API gateway failed count, matching the host names in that panel title:

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE (WPLALJ2CO OR WPLALJ2BF) FAILURE
| stats count
```

Kappa uses the same shape with WPLALJ2BC and WPLALJ2BB.

Click the chart. In the configuration, set the major value color:

| Panel | Color |
|---|---|
| APIGateway FAILURE | Red. |
| APIGateway SUCCESS | Green. |
| IS Failure | Red. |
| IS Success | Green. |
| English or Kappa failed count | Red. |

A red 0 is the failure counter sitting at zero. A green 0 is the success counter sitting at zero. On this screen, IS Success and IS Failure are both 0, so neither counter received an event in the last 15 minutes.

The word FAILURE above 536 is a caption or a second line on that single value. Set the panel title to the long name, for example `EIP 12/15 DCI (English)`, and the caption to `APIGW WPLALJ2CO & WPLALJ2BF Failed Count`.

### Single value for ND Mode

This box prints a letter, not a count. The screen shows A for Kappa and A for English.

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE
| stats latest(nd_mode) AS mode
```

Use the real field name from the existing panel. Set the caption to `EIP ND Mode`. The letter A is whatever the latest event contains. Confirm the meaning of A in that search before you treat it as healthy.

### Table for servers

Add a chart. Choose Table.

Mediator servers, matching the right-hand table:

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE (host="WPLALJ2BF.axajp.intraxa" OR host="WPLALJ2CO.axajp.intraxa")
| stats latest(MS_ResultMS_Status) AS MS_ResultMS_Status by host
```

Integration servers:

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE (host="WPLALJ2C1.axajp.intraxa" OR host="WPLALJ2BO.axajp.intraxa")
| stats latest(IS_ResultIS_Status) AS IS_ResultIS_Status by host
```

Title the first table `DCI_Mediator_Servers` and the second `DCI_Integration_Servers`. The right-hand tables on this screen show `EIP_UP` for all four hosts.

### When a box says No results found

The panel is saved. The search matched nothing in the current 15 minutes. On this screen that is the Kappa failed-count box, the left mediator table, and the left integration table.

| What you do | Why |
|---|---|
| Edit the panel and choose Open in search. | You see the real SPL. |
| Run the same search for the last 24 hours. | A quiet 15 minutes can still have older events. |
| Compare the host list with the panel that has rows. | A different host filter explains an empty copy beside a full copy. |

### How this screen reads

| Box | What the last 15 minutes show |
|---|---|
| APIGateway FAILURE | 538 failure events. |
| APIGateway SUCCESS | 19,187 success events. Traffic is still being counted. |
| IS Success | 0. |
| IS Failure | 0. |
| Kappa API GW failed count | No matching events for WPLALJ2BC and WPLALJ2BB. |
| English API GW failed count | 536 for WPLALJ2CO and WPLALJ2BF. |
| Both ND Mode boxes | The letter A. |
| Right mediator table | Two hosts, both EIP_UP. |
| Right integration table | Two hosts, both EIP_UP. |

## Data flow map

```
Search by Time = Last 15 minutes
        |
        +--> APIGateway FAILURE search --> single value 538, red
        +--> APIGateway SUCCESS search --> single value 19187, green
        +--> IS Success search --> single value 0, green
        +--> IS Failure search --> single value 0, red
        |
        +--> Kappa hosts WPLALJ2BC WPLALJ2BB --> no events
        +--> Kappa ND mode search --> letter A
        +--> English hosts WPLALJ2CO WPLALJ2BF --> 536, red
        +--> English ND mode search --> letter A
        |
        +--> left mediator search --> no events
        +--> right mediator search --> two hosts, EIP_UP
        +--> left integration search --> no events
        +--> right integration search --> two hosts, EIP_UP
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the screenshot shows. |
| `2-result.md` | Build steps and the searches. |
| `3-glossary.md` | Terms. |
| `9-splunk-incident-helper-dashboard-follow.txt` | Same steps for mobile. |
| `9.sh` | Copy commands. |

Commands: [9.sh](9.sh)
