# Glossary

| Term | What it means |
| --- | --- |
| Workflow template YAML | Human-readable Dynatrace Automation import format with wrapper + `workflow:` |
| Workflow JSON | Full workflow object Dynatrace Upload/API expects |
| Davis Problem | Dynatrace-detected issue that opens and closes |
| `onProblemClose` | Trigger flag: false = open path; true = close path |
| `run-javascript` | Task type that runs JS and can call external HTTP APIs |
| `correlation_id` | ServiceNow field storing Dynatrace Problem ID |
| `dedup_key` | PagerDuty key that groups trigger and resolve for one alert |
| `assignMap` | In-script table mapping app tag → SNOW group/biz/L1–L3/runbook |
| `sys_id` | ServiceNow internal UUID for a record |
| Cross-link | PATCH work notes so INC shows the PD dedup key |
| Events API v2 | PagerDuty HTTP API for trigger/resolve |
| Placeholder | `__NAME__` string you must replace with real secrets/IDs |
