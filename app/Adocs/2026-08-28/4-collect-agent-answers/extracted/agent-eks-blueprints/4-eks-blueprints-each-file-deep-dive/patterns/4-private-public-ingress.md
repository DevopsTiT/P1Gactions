# Private Public Ingress Pattern Files

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
| Scope | File-by-file deep dive for **Private Public Ingress Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** aws + helm constraints.
- **What it contains:** No kubernetes provider (ingress via Helm addons only).
- **Why it matters:** Two ingress-nginx Helm installs.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Bottlerocket EKS + dual ingress-nginx (external/internal) + ALB controller.
- **What it contains:** Two SGs; two `eks_blueprints_addons` modules for nginx; third for ALB controller 1.6.0; VPC.
- **Why it matters:** Split public vs private ingress classes with dedicated NLBs/SGs.
- **Notable settings:**
  - AMI `BOTTLEROCKET_x86_64`, 3 nodes
  - External: scheme `internet-facing`, SG open 80/443 to `0.0.0.0/0`
  - Internal: scheme `internal`, SG limited to VPC CIDR
  - Classes `ingress-nginx-external` / `ingress-nginx-internal`
  - `loadBalancerClass: service.k8s.aws/nlb`, topology spread, minAvailable 2

### outputs.tf
- **What it is:** kubectl helper with alias.
- **What it contains:** `update-kubeconfig --alias`.
- **Why it matters:** Convenience naming for multi-cluster local configs.
- **Notable settings:** Alias = cluster name.

### README.md
- **What it is:** Explains dual controllers + ingressClassName usage.
- **What it contains:** Deploy; TODO validate; destroy.
- **Why it matters:** How apps choose public vs private ingress.
- **Notable settings:** Set `ingressClassName` to external or internal class.

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
