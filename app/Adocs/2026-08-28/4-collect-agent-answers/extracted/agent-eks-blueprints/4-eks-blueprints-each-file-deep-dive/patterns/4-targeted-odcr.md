# Targeted ODCR Pattern Files

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
| Scope | File-by-file deep dive for **Targeted ODCR Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for ODCR pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for ODCR GPU MNG in `eks.tf`.
- **Notable settings:** Standard 3-AZ VPC.

### eks.tf
- **What it is:** EKS MNG targeting a Capacity Reservation resource group + ODCR resource group resources.
- **What it contains:** `capacity_reservation_arns` var; EKS; `odcr` + `default` MNGs; `aws_resourcegroups_group` CapacityReservationPool; group memberships.
- **Why it matters:** Shows targeted ODCR via resource group ARN (add/remove capacity without LT rewrite).
- **Notable settings:**
  - `p5.48xlarge`, NVIDIA AMI, EFA, RAID0, GPU taint
  - `capacity_reservation_resource_group_arn = aws_resourcegroups_group.odcr.arn`
  - AZ-pinned first private subnet
  - Duplicate min/max/desired blocks (2/2/2 then 4/5/2 — last wins in HCL)

### helm.tf
- **What it is:** NVIDIA + EFA device plugins (same pattern as CBR/GPU).
- **What it contains:** nvidia 0.17.1; efa v0.5.7 with GPU toleration.
- **Why it matters:** Device exposure for ODCR GPU nodes.
- **Notable settings:** EFA nodeSelector + nvidia toleration.

### README.md
- **What it is:** Three-component ODCR recipe + console validation (images skipped).
- **What it contains:** AZ pin, LT reservation spec, resource group container model.
- **Why it matters:** Explains why resource groups allow capacity changes without node group disruption.
- **Notable settings:** Links to EC2 ODCR tutorials.

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
