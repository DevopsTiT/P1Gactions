# Investigation

| What was checked | Finding |
|---|---|
| Screen the JSON came from | "Run workflow" test dialog of the Problem trigger. It is the trigger event, not the SILVA request. |
| Affected entity | SERVICE-4C92DDBDD78986D0, type SERVICE. |
| Related entity | PROCESS_GROUP-FBFA7DE3E44C269C (nginx compass-proxy-pbco). |
| Problem id | P-260915351, status ACTIVE, transition UPDATED. |
| snow-service tag | Not present. |
| Application tags | dt.cost.product and app both have COMPASSPROXY and ILLUSTRATION-PROPOSAL-AXA-COMPASS. |
| Environment tag | env:TST. |
| Ownership hints | bu:NB-IT-COMPASS-AXAJP, company:ALJ, dt.cost.costcenter:ALJ. |
| host tag | Contains Kubernetes pod names, which are temporary and not in the CMDB. |
| Security context | ALJ_APPLICATION_COMPASSPROXY_TST and similar values. |

Conclusion: the event gives the application and the environment, but no SILVA names. The SILVA side must be looked up once and stored in a mapping.
