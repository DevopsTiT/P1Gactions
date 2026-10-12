# Control-M Processes And Cost Investigation

| Item | Evidence on screen |
|---|---|
| Processes query end | Container lookup, availability math with interval in nanoseconds, 17 records, availability 100.00, healthIndicators null |
| CoPilot query | filter in(entity.name, p_ctmat, p_ctmag), lookup host with prefix host., 24 records |
| Cost query | BILLING_USAGE_EVENT, cost split by dt.cost.product, filter EIP, traces append, data json price list in EUR |
