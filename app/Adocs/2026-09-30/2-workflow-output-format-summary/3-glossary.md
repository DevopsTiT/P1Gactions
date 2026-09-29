# Glossary

| Term | What it means | Why you care |
|---|---|---|
| dynatrace_alert | The alert facts taken from the Dynatrace event | Basis for every text and routing value |
| servicenow_enrichment | The SILVA business service record that owns the alert | Fills business service, company and group on the incident |
| decision | The workflow's choice to open or skip, and who gets it | What OPEN will do |
| Payload | The exact JSON body of an API call | What SILVA or PagerDuty would receive |
| sys_id | A 32-character SILVA record id | Reference fields are set reliably with it |
| BSN number | Business service number in SILVA | Easy way to look the service up |
| u_bbsa_id | AXA business service id | Identifies the service across AXA tools |
| business_criticality | How critical the service is (1 is highest) | Can drive priority later |
| correlation_id | External id on the incident | CLOSE finds the ticket with it |
| dedup_key | PagerDuty incident key | Trigger and resolve must match |
| match_method | How the service was found | How much to trust the result |
| service_candidates | Ranked list of possible services | Lets you choose when the workflow cannot |
