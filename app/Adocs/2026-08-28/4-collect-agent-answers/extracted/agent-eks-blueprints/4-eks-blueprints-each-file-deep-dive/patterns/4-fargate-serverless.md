# Fargate Serverless Pattern Files

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
| Scope | File-by-file deep dive for **Fargate Serverless Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** Provider constraints for Fargate pattern.
- **What it contains:** aws, helm, kubernetes `>= 2.20`.
- **Why it matters:** Kubernetes provider used for sample app.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Fargate-only EKS + addons + 2048 sample app.
- **What it contains:** EKS Fargate profiles; blueprints-addons (CoreDNS Fargate sizing, Fluent Bit, ALB controller); VPC; Deployment/Service for `app-2048`.
- **Why it matters:** Shows serverless data plane patterns and Fargate-specific CoreDNS/logging.
- **Notable settings:**
  - Profiles: `app-*` and `kube-system`
  - `create_cluster_security_group/create_node_security_group = false`
  - CoreDNS `computeType = Fargate`, cpu/memory `0.25` / `256M`
  - `enable_fargate_fluentbit = true`, `flb_log_cw = true`
  - ALB controller with `vpcId` set
  - App toleration `eks.amazonaws.com/compute-type=fargate`

### outputs.tf
- **What it is:** kubectl helper output.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Cluster access after apply.
- **Notable settings:** Region-scoped update-kubeconfig.

### README.md
- **What it is:** Validate Fargate nodes, Fluent Bit CW logs, ALB ingress example.
- **What it contains:** Sample outputs; ingress create annotations; destroy partial.
- **Why it matters:** Operational checklist for serverless cluster.
- **Notable settings:** Ingress class `alb`, scheme internet-facing, target-type ip.

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
