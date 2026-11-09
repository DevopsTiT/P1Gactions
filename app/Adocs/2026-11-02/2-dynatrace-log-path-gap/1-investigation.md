# Investigation

| Source | Finding |
|---|---|
| Chat title | Daily Standup: Masking PII data in Dynatrace. |
| Log path | `/app/ICM_CPW/log/ap/default.log`. |
| Included | CEAAI016, CEAA9026, CEAA9027. |
| Missing | CEAA20F7, host group `HOST_GROUP-9034BF4FC7D158B2`. |
| Storage resource | `dynatrace_log_storage.alj_icmclmpay_prod_app`, `send_to_storage = true`. |
| Custom source | `dynatrace_log_custom_source.alj_icmclmpay_app_logs`. The photo cuts off after `scope`. |
