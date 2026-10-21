# Investigation

## What this is

PagerDuty AI answers inside the normal PagerDuty Slack and Teams apps. It does not replace PagerDuty, and it is not the Dynatrace Hub Slack Connection.

## Setup order

1. License — `/ai` works
2. Connect Slack and/or Teams PagerDuty app
3. AI Settings → Chat Integrations Connected + On
4. Each SRE links account
5. Connect a test channel

## Runtime order

1. Incident opens in PagerDuty
2. Message appears in Slack / Teams
3. You ask `@PagerDuty` or `/pd scribe`
4. AI answers in the same chat
5. You fact-check and act in PagerDuty
