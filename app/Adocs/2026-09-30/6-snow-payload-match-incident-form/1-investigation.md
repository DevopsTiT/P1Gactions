# Investigation

| Form field on INC30340215 | Value seen | Mandatory mark |
|---|---|---|
| Caller | Dynatrace JP | Yes |
| On Behalf Of | Dynatrace JP | No |
| Contact type | Event | No |
| Company | AXA GROUP OPERATIONS | No |
| Environment | Development | Yes |
| Business service | Third Party Services Monitoring Application | Yes |
| Service Offering | Third Party Services Monitoring Application | Yes |
| SO Display Name | Silver - Production | Read only |
| Configuration Item | ts12.hk.intraxa | No |
| Category | Other | Yes |
| Subcategory | Other | Yes |
| Impact | 4 - Low | No |
| Urgency | 4 - Low | No |
| Priority | 4 - Low | Calculated |
| Assignment group | InfraSupport_Dist-WindowsHK_L2_ASIA | No |
| Short description | [DYNATRACE JAPAN][TS12.hk.intraxa] - EPAS Filter Error... | Yes |
| Summary | Event text + Additional Information JSON | Yes |

| Gap in the old v4 payload | Fix |
|---|---|
| No caller, on behalf of, category, subcategory | Added as settings |
| Impact and urgency sent as labels | Now sent as values "4" |
| Business service and offering could be empty | Default service and offering fallback |
| Summary JSON had a different layout | Now matches correlation_id, discovered_name, dynatrace_severity, environmentId, environmentName, event_properties |
| Short description used "service on host" | Now uses CI or host only |
