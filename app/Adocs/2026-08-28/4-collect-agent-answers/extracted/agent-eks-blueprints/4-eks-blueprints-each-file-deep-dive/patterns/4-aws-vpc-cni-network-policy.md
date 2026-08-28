# VPC CNI Network Policy Pattern Files

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
| Scope | File-by-file deep dive for **VPC CNI Network Policy Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** VPC CNI native NetworkPolicy demo (Stars).
- **What it contains:** Deploy/validate via management-ui LB URL.
- **Why it matters:** Maps to AWS docs Stars scenario (CNI ≥ 1.14, k8s ≥ 1.25).

### versions.tf / outputs.tf / variables.tf
- **What they are:** Provider pins; kubectl output; empty variables file.

### main.tf
- **What it is:** EKS + VPC CNI with NetworkPolicy enabled + demo Helm + six NetworkPolicies.
- **What it contains:** `enableNetworkPolicy: true`; Helm `./charts/demo-application`; default-deny + allow-ui/frontend/backend policies.
- **Notable settings:** CNI create timeout 25m.

### charts/demo-application/Chart.yaml / .helmignore
- **What they are:** Helm packaging for Stars demo (v1.0.0).

### charts/.../templates/*
| File | Role |
|------|------|
| `stars-ns.yaml` | Namespace `stars` |
| `client-ns.yaml` | Namespace `client` (`role=client`) |
| `management-ui-ns.yaml` | Namespace `management-ui` |
| `frontend-deploy/svc` | star-probe frontend :80 |
| `backend-deploy/svc` | star-probe backend :6379 |
| `client-deploy/svc` | star-probe client :9000 |
| `management-ui-deploy/svc` | star-collect UI LoadBalancer :80→9001 |

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
