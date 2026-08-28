# IPv6 EKS Cluster Pattern Files

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
| Scope | File-by-file deep dive for **IPv6 EKS Cluster Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** AWS provider pin for IPv6 pattern (module v21 era).
- **What it contains:** aws `>= 6.0`.
- **Why it matters:** Matches VPC/EKS module major upgrades used below.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Dual-stack VPC + IPv6 EKS cluster.
- **What it contains:** EKS module `~> 21.0.7` with `ip_family = "ipv6"`; VPC `~> 6.0.1` with IPv6 prefixes and egress-only IGW.
- **Why it matters:** Shows IPv6 cluster + subnet IPv6 assignment knobs.
- **Notable settings:**
  - `ip_family = "ipv6"`, `create_cni_ipv6_iam_policy = true`
  - `kubernetes_version = "1.33"`, `endpoint_public_access = true`
  - `enable_ipv6`, `create_egress_only_igw = true`
  - Public prefixes `[0,1,2]`, private `[3,4,5]`, `private_subnet_enable_dns64 = false`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl` referencing `module.eks.cluster_name`.
- **Why it matters:** Post-deploy access.
- **Notable settings:** Region `us-west-2`.

### README.md
- **What it is:** Validate pods/nodes show IPv6 addresses.
- **What it contains:** `kubectl get pods/nodes -o wide` sample IPv6 INTERNAL-IP.
- **Why it matters:** Success criteria for the pattern.
- **Notable settings:** Expect pod IPs like `2600:1f13:...`.

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
