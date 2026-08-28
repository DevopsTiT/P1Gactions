# Fully Private Cluster Pattern Files

```
reading this pattern's files
  start with README.md → intent + validate/destroy
  then main.tf / versions.tf → providers + locals
  then vpc.tf or VPC block → network
  then eks.tf or EKS block → cluster
  then addons/helm/karpenter/okta/... → day-2 software
  then yaml manifests → runtime CRs / demos
  stuck? → check README destroy order + FAQ ENI/token issues
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Scope | File-by-file deep dive for **Fully Private Cluster Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** Minimal provider set (AWS only).
- **What it contains:** aws `>= 5.34, < 6.0`.
- **Why it matters:** No Helm/K8s providers — infra-only private cluster.
- **Notable settings:** Commented e2e backend.

### main.tf
- **What it is:** Private VPC (no NAT/public) + VPC endpoints + private EKS.
- **What it contains:** EKS `~> 20.11` with private subnets only; VPC without public subnets/`enable_nat_gateway = false`; Interface+Gateway endpoints.
- **Why it matters:** Demonstrates air-gapped-style cluster dependency on VPC endpoints.
- **Notable settings:**
  - No `cluster_endpoint_public_access = true` (module default private)
  - Endpoints: s3 gateway + autoscaling, ecr.api/dkr, ec2, ec2messages, elb, sts, kms, logs, ssm, ssmmessages
  - Endpoint SG allows HTTPS from VPC CIDR

### outputs.tf
- **What it is:** kubectl config tip (assumes reachable private API).
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Access requires network path into VPC (VPN/Direct Connect/bastion).
- **Notable settings:** Same update-kubeconfig pattern as other patterns.

### README.md
- **What it is:** Private cluster requirements and endpoint list.
- **What it contains:** Required VPC endpoints list; validate nodes/pods; destroy.
- **Why it matters:** Documents why endpoints exist and extra ones (APS, etc.).
- **Notable settings:** Mentions private endpoint access for node registration.

---

## Data flow map

```
README (intent)
  → versions/main (tooling + locals)
  → vpc / network
  → eks / control plane + nodes
  → addons / helm / identity / secrets
  → yaml demos (apply after TF or via GitOps)
  → outputs (kubectl / SSO helpers)
```

## Related files

| File | Role |
|------|------|
| — | — |
| Parent index | `../4-eks-blueprints-each-file-deep-dive.md` |
| Commands | `../4.sh` |

## Commands

See [4.sh](../4.sh) for deploy/validate one-liners. Review before running.
