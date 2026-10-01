# Investigation

| What was checked | Finding |
|---|---|
| Workflow inputs | `metadata.inputs: []` and `workflow.input: {}`. No input form. |
| prepare-close | Uses the live event; if none, uses SAMPLE_EVENT. |
| correlation_id and dedup_key | Both built from `display_id`. |
| Problems API | Only called on real events with `event.id`; skipped for sample runs. |
