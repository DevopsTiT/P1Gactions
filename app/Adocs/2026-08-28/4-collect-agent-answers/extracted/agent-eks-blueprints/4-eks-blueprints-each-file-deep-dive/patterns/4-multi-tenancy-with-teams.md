# Multi Tenancy Teams Pattern Files

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
| Scope | File-by-file deep dive for **Multi Tenancy Teams Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** Provider pin (aws + kubernetes).
- **What it contains:** No helm.
- **Why it matters:** Teams module uses kubernetes resources.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** EKS with aws-auth managed by teams modules (admin + red/blue).
- **What it contains:** EKS `~> 19.21`; `eks-blueprints-teams` admin + for_each red/blue; VPC; kubernetes provider via `aws_eks_cluster_auth` token.
- **Why it matters:** Namespace isolation with quotas/limit ranges and IAM/aws-auth roles per team.
- **Notable settings:**
  - `manage_aws_auth_configmap = true`
  - Admin: `enable_admin = true`, users = caller ARN
  - Dev teams: namespaces `team-red`/`team-blue` with CPU/mem/pod quotas and LimitRanges
  - Cluster version `1.29`

### outputs.tf
- **What it is:** Per-team kubeconfig role ARN helpers.
- **What it contains:** Admin + list of dev team `update-kubeconfig --role-arn` commands.
- **Why it matters:** Shows how each tenant assumes its IAM role.
- **Notable settings:** Role ARNs from teams modules.

### README.md
- **What it is:** High-level tenancy description (TODO validate).
- **What it contains:** team-red/blue + admin overview.
- **Why it matters:** Intent statement for the pattern.
- **Notable settings:** Validation section marked TODO.

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
