# Dynatrace Notebook Tags And Billing Result

| Cell | Verdict | Fix |
|---|---|---|
| I | Wrong filter value | osType == "WINDOWS" |
| J | Tags not loaded | fieldsAdd tags, lower-case match |
| K | Three bugs | fieldsAdd tags, in(), entity.name |
| L | Works | Ignore partial first and last day |
| M | Works, cut | limit 10000 |
| N | Cut off | Count distinct hosts |
