# PrivateLink Access Pattern Files

```
reading this pattern's files
  start with README.md → intent + validate/destroy
  then providers/versions/main → locals
  then vpc / eks → infra
  then addons/helm/bootstrap → software
  then yaml/charts → runtime demos
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Scope | File-by-file deep dive for **PrivateLink Access Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Private EKS API access via PrivateLink from a client VPC.
- **What it contains:** Deploy order (eventbridge+nlb first), SSM connectivity test, kubectl from client EC2.
- **Why it matters:** End-to-end private API path without peering/TGW.
- **Notable settings:** `ssm_test` should return `ok`.

### versions.tf
- **What it is:** Provider pins including DNS.
- **What it contains:** aws, dns, kubernetes.
- **Why it matters:** NLB A-record lookup drives SG rules.
- **Notable settings:** `dns` `>= 3.0`.

### main.tf
- **What it is:** Shared locals/provider.
- **What it contains:** aws provider; AZs; name/region/CIDR/tags.
- **Why it matters:** Shared by eks/client/privatelink files.

### eks.tf
- **What it is:** Private EKS + private VPC + VPC endpoints + IGW for NLB.
- **What it contains:** Private endpoint EKS 1.30; access entry for client EC2; NLB IP SG rules; no NAT; interface/gateway endpoints.
- **Why it matters:** Fully private data plane with endpoint-only AWS API access.

### client.tf
- **What it is:** Demo client VPC + SSM EC2 test harness.
- **What it contains:** Client VPC with NAT; EC2 with SSM + EKS describe; user-data installs kubectl/awscli v2.
- **Why it matters:** Validate PrivateLink connectivity.
- **Notable settings:** Same CIDR as cluster VPC but separate VPC.

### privatelink.tf
- **What it is:** Internal NLB → Endpoint Service → client interface endpoint + Lambdas.
- **What it contains:** ALB module as NLB; endpoint service; Route53 private zone; create/delete ENI Lambdas; EventBridge.
- **Why it matters:** Registers EKS API ENI IPs into NLB TG dynamically.
- **Notable settings:** Health check HTTPS `/readyz`; CreateNetworkInterface → register; rate(15m) cleanup.

### outputs.tf
- **What it is:** SSM session + connectivity test snippets.
- **What it contains:** `ssm_start_session`, `ssm_test`.

### lambdas/create_eni.py
- **What it is:** Registers new EKS API ENI private IP on NLB TG:443.
- **Why it matters:** Keeps PrivateLink path healthy as ENIs appear.

### lambdas/delete_eni.py
- **What it is:** Periodically deregisters unhealthy TG IPs no longer matching EKS ENIs.
- **Why it matters:** Cleans stale targets after ENI churn.

## Data flow map

```
README → versions/main → vpc → eks → addons/helm/gitops → yaml demos → outputs
```

## Related files

| File | Role |
|------|------|
| Index | `../4-eks-blueprints-each-file-deep-dive.md` |
| Commands | `../4.sh` |

## Commands

See [4.sh](../4.sh).
