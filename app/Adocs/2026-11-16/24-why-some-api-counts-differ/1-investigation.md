# Investigation

| API | Splunk | Dynatrace | Gap |
|---|---|---|---|
| `customer-info-V2` | 26,902 | 26,991 | 89 |
| `policy-management-V1` | 18,637 | 18,636 | 1 |
| Premium cash value API | 15,365 | 15,448 | 83 |
| `jp-Distributing-Sell-GenerateFormImage-v2-vs` | 4,546 | 4,394 | 152 |
| `jp-CoreBusiness-ServiceManagement-ICMCase-v1-vs` | 1,910 | 1,499 | 411 |
| `customer-info-V1` | 15,451 | 13,512 | 1,939 |

Dynatrace window: 13:55 to 14:55. Splunk Last 1 hour at 15:07 is about 14:07 to 15:07.

The parse keeps a line when the text is `API: ` then the name then ` API Version`.
