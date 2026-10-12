# Dynatrace Notebook Tags And Billing Investigation

| Cell | Evidence on screen |
|---|---|
| I | Same as part 3, 0 records |
| J | Four fetches with append, no fieldsAdd tags, five exact tag compares, 0 records |
| K | filter tags == "[AWS]global:env:preprod", fields name = hosts, 0 records |
| L | BILLING_USAGE_EVENT, Infrastructure Monitoring, makeTimeseries 24h, flat bars, short first and last |
| M | 30-day window, top hosts at 720.00 hours, 1,000 records with warning |
| N | Title only |
