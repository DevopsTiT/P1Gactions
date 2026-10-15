# Multilogforwarder Life Only No Portals

## Decision tree

```
Previous result: log.source = multilogforwarder-log-handler-dynatrace
 namespaces end with -prod-axa-li-jp? → yes, all 11 (AXA Life)
 portals-amp in the list? → no
  portals-amp logs go to S3 axa-gi-jp-logforwarders-prod (General Insurance)
   → GI has no forwarder into Dynatrace yet (or not for portals)
   → onboarding = add portals-amp to a forwarder that sends to Dynatrace
 Check 2 finds a GI forwarder source? → ask that team to add portals-amp
 Check 2 finds only the li-jp forwarder? → request a GI forwarder or reuse this one
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the previous result show? | One log forwarder sends Kubernetes logs into Dynatrace for 11 namespaces. |
| Whose namespaces? | All end with `-prod-axa-li-jp`, which is AXA Life Japan. |
| Is portals-amp there? | No. portals-amp belongs to AXA General Insurance (`axa-gi-jp`). |
| What does it mean? | A working forwarder path exists, so onboarding portals-amp is a config request, not a new design. |

## Summary

The result is from 10/12 23:34 to 10/13 00:34. It lists every namespace the `multilogforwarder-log-handler-dynatrace` source sent in that hour. Only AXA Life namespaces appear. portals-amp writes to the GI bucket `axa-gi-jp-logforwarders-prod`, which feeds Splunk only. This matches today's finding that the only Dynatrace hits were Splunk's own search logs.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Log forwarder | A small service, often a Lambda function, that reads logs from S3 or CloudWatch and sends them to a tool like Dynatrace. |
| `log.source` | Where Dynatrace says the log came from. Here it is the forwarder's name. |
| Namespace | A Kubernetes folder that groups one app's pods. |
| `li-jp` | AXA Life Insurance Japan. |
| `gi-jp` | AXA General Insurance Japan, where portals-amp runs. |

### Previous result (10/13, 1 hour)

| Namespace | Lines |
|---|---|
| compassproxy-prod-axa-li-jp | 154,642 |
| axahp-prod-axa-li-jp | 32,504 |
| nbwf-prod-axa-li-jp | 8,600 |
| orgchangerequestmgmt-prod-axa-li-jp | 7,133 |
| www2rp-prod-axa-li-jp | 4,688 |
| taxdeduction-prod-axa-li-jp | 2,856 |
| documentuploadproxy-prod-axa-li-jp | 2,852 |
| capportalsystemapi-prod-axa-li-jp | 2,138 |
| forthehappyfuture-prod-axa-li-jp | 664 |
| pbcosupportbe-prod-axa-li-jp | 12 |
| capportalprocessapi-prod-axa-li-jp | 8 |

### What it tells us

| Finding | What it means |
|---|---|
| All 11 names end with `-prod-axa-li-jp` | The forwarder only carries AXA Life apps. |
| No `portals` namespace | portals-amp is not sent by this forwarder. |
| No `-gi-` namespace | No General Insurance app is sent by this forwarder. |
| The forwarder fills `k8s.namespace.name` | If portals-amp were forwarded, today's Step 1 would have shown a namespace, not null. |

## Result

Run the three checks in `10-multilogforwarder-li-only-no-portals.dql` to confirm with today's data.

| Check | What it answers |
|---|---|
| Check 1 | Is the forwarder still sending only li-jp namespaces? |
| Check 2 | Is there a second forwarder source, for example one for GI? |
| Check 3 | Does any portals or GI namespace exist in Dynatrace at all? |

Add this to the onboarding request: "AXA Life apps already reach Dynatrace through `multilogforwarder-log-handler-dynatrace`. Please add portals-amp-backend (GI, bucket `axa-gi-jp-logforwarders-prod`) to that forwarder or a GI equivalent."

## Data flow map

```
AXA Life pods (li-jp) → logs → multilogforwarder-log-handler-dynatrace → Dynatrace   (11 namespaces)

portals-amp pods (gi-jp) → logs → S3 axa-gi-jp-logforwarders-prod → Splunk           (68 events/h)
                                                                  ✗ no forwarder to Dynatrace
```

## Related files

| File | Purpose |
|---|---|
| `10-multilogforwarder-li-only-no-portals.dql` | Check 1, 2 and 3 |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Previous result table |
| `2-result.md` | Next steps and request wording |
| `3-glossary.md` | Terms |
| `10.sh` | Git one-liners (not run) |

## Commands

See `10.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/10-multilogforwarder-li-only-no-portals
git commit -m "multilogforwarder li only no portals"
git push
```
