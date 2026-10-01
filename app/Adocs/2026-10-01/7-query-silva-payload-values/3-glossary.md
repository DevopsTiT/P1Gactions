# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Table API | `/api/now/v2/table/<table>` REST endpoint | Every query here uses it |
| `sysparm_query` | Filter, for example `name=X^active=true` | Picks the rows |
| `sysparm_fields` | Columns to return | Keeps output short |
| `sysparm_display_value=all` | Return both stored value and label | Shows what to send |
| `sys_choice` | Table of drop-down values per table and field | Answers choice fields |
| `element` | Field name inside `sys_choice` | For example `u_environment` |
| `dependent_value` | Parent choice for dependent drop-downs | Subcategory depends on category |
| `-G --data-urlencode` | curl options that encode query text safely | Avoids malformed URL errors |
