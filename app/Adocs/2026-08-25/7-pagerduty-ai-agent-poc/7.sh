# PagerDuty AI Agent POC — one-liners (placeholders only; do not commit real secrets)
# Path: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-25/7-pagerduty-ai-agent-poc/7.sh
export PD_ROUTING_KEY='REPLACE_ME_EVENTS_KEY'
export PD_API_TOKEN='REPLACE_ME_REST_TOKEN'
export PD_SERVICE_ID='REPLACE_ME_TEST_SERVICE_ID'
export PD_FROM_EMAIL='ai-agent-poc@example.com'
export PD_INCIDENT_ID='REPLACE_ME_INCIDENT_ID'
curl -sS -X POST https://events.pagerduty.com/v2/enqueue -H 'Content-Type: application/json' -d "{\"routing_key\":\"${PD_ROUTING_KEY}\",\"event_action\":\"trigger\",\"dedup_key\":\"poc-ai-agent-001\",\"payload\":{\"summary\":\"POC: AI agent test page\",\"severity\":\"ai-agent-poc\",\"source\":\"cursor-agent-poc\",\"severity_class\":\"poc\"}}"
curl -sS -G 'https://api.pagerduty.com/incidents' -H 'Accept: application/vnd.pagerduty+json;version=2' -H "Authorization: Token token=${PD_API_TOKEN}" --data-urlencode "service_ids[]=${PD_SERVICE_ID}" --data-urlencode 'statuses[]=triggered' --data-urlencode 'statuses[]=acknowledged'
curl -sS -X PUT "https://api.pagerduty.com/incidents/${PD_INCIDENT_ID}" -H 'Accept: application/vnd.pagerduty+json;version=2' -H "Authorization: Token token=${PD_API_TOKEN}" -H 'Content-Type: application/json' -H "From: ${PD_FROM_EMAIL}" -d '{"incident":{"type":"incident","status":"acknowledged"}}'
curl -sS -X POST "https://api.pagerduty.com/incidents/${PD_INCIDENT_ID}/notes" -H 'Accept: application/vnd.pagerduty+json;version=2' -H "Authorization: Token token=${PD_API_TOKEN}" -H 'Content-Type: application/json' -H "From: ${PD_FROM_EMAIL}" -d '{"note":{"content":"[ai-agent-poc] Triage draft: checking Dynatrace problem link next."}}'
curl -sS -X POST https://events.pagerduty.com/v2/enqueue -H 'Content-Type: application/json' -d "{\"routing_key\":\"${PD_ROUTING_KEY}\",\"event_action\":\"resolve\",\"dedup_key\":\"poc-ai-agent-001\"}"
