# ML Capacity Block Pattern Files

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
| Scope | File-by-file deep dive for **ML Capacity Block Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for capacity-block GPU pattern.
- **What it contains:** `aws` + `helm`; VPC `~> 5.0`; region `us-west-2`.
- **Why it matters:** Shared infra for CBR-backed GPU MNG in `eks.tf`.
- **Notable settings:** `region = "us-west-2"`, single NAT, private subnets for EKS.

### eks.tf
- **What it is:** EKS + MNG wired to an ML Capacity Block Reservation.
- **What it contains:** Required `capacity_reservation_id` variable; EKS `~> 20.34`; `cbr` + `default` MNGs.
- **Why it matters:** Shows exact CBR knobs: AZ-pinned subnet, `CAPACITY_BLOCK`, market options, reservation target.
- **Notable settings:**
  - `ami_type = "AL2023_x86_64_NVIDIA"`, `p5e.48xlarge`
  - `capacity_type = "CAPACITY_BLOCK"`
  - `instance_market_options.market_type = "capacity-block"`
  - `capacity_reservation_id = var.capacity_reservation_id`
  - `subnet_ids = [element(private_subnets, 0)]` (AZ match TODO)
  - GPU taint + EFA/GPU labels + RAID0 + `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia-device-plugin 0.17.1; aws-efa-k8s-device-plugin v0.5.7 with GPU toleration.
- **Why it matters:** Completes GPU/EFA scheduling stack on CBR nodes.
- **Notable settings:** EFA `nodeSelector` + `nvidia.com/gpu` toleration.

### README.md
- **What it is:** CBR usage docs with three required components.
- **What it contains:** AZ restriction, LT reservation args, `capacity_type = CAPACITY_BLOCK`.
- **Why it matters:** Explains common AZ mismatch failures.
- **Notable settings:** Links to EKS/EC2 capacity blocks docs.

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
