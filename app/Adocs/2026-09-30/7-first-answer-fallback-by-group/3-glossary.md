# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Dot-walk | Querying a field of a referenced record, like `assignment_group.name` | Lets you search services by group name |
| LIKE | "Contains" match in a SNOW query | Finds names that include the text |
| First answer | Taking the first row a query returns | Simple fallback when no exact link exists |
| Environment match | Preferring a row whose name contains the environment label | Picks the Test service for a Test alert |
| --data-urlencode | curl option that encodes special characters | Fixes "URL rejected: Malformed input" |
| from | Output field that says how a value was found | Tells a real link from a guess |
