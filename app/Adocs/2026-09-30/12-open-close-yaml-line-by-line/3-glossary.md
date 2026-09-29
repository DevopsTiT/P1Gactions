# Glossary

| Term | What it means | Why you care |
|---|---|---|
| YAML | Indentation-based config format | The workflow frame |
| Task id | The key under `tasks:` | Used in predecessors and `ex.result()` |
| predecessors | Tasks that must run first | Sets the order |
| conditions.states | Required result of the predecessor | `OK` means only after success |
| run-javascript | Dynatrace action that runs a script | Where the logic lives |
| `export default async function` | The script entry point | Runs once per execution |
| `ex.event()` | The trigger event | Input for task 1 |
| `ex.result("id")` | Another task's return value | How tasks share data |
| `fetch` | HTTP call from the script | Talks to SILVA and PagerDuty |
| Basic auth | User and password in a header | How SILVA checks the caller |
| `sysparm_display_value=all` | SILVA returns value and name | Gives sys_id and label together |
| `throw new Error` | Makes the task fail | Shows red in the run |
