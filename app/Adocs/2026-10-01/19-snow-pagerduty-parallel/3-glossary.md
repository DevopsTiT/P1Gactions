# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Predecessor | Task that must finish before this one starts | Same predecessor = parallel start |
| Parallel tasks | Tasks that run at the same time | PD pages even if SILVA is slow |
| Race condition | Two tasks reading and writing at the same moment | Why PD does not check SILVA for duplicates |
| dedup_key | PagerDuty key for one alert | Repeat triggers do not create new PD incidents |
| correlation_id | Problem id on the SILVA incident | Links the PD alert to the SILVA ticket |
