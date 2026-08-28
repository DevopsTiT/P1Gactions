# GitOps Patterns Files

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
| Scope | File-by-file deep dive for **GitOps Patterns Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

## getting-started-argocd

### README.md
- **What it is:** GitOps Bridge single-cluster ArgoCD tutorial.
- **What it contains:** Deploy flow, secret annotations/labels, apply bootstrap yaml, fork guidance.
- **Why it matters:** Canonical GitOps Bridge walkthrough.

### versions.tf / variables.tf / outputs.tf
- **What they are:** Pins; addon/workload git vars; kubectl/ArgoCD access outputs.
- **Notable settings:** Defaults k8s 1.28; addons repo `eks-blueprints-add-ons`; workload path this pattern’s `k8s/`.

### main.tf
- **What it is:** VPC + EKS + blueprints addons (no K8s create) + gitops-bridge bootstrap.
- **Notable settings:** `create_kubernetes_resources = false`; cluster `getting-started-gitops`.

### destroy.sh
- **What it is:** Ordered teardown deleting AppSets/Ingress before TF destroy (avoids orphan ALBs).

### bootstrap/addons.yaml / bootstrap/workloads.yaml
- **What they are:** ArgoCD ApplicationSets applied manually after Terraform.
- **Notable settings:** `preserveResourcesOnDeletion: true`.

### k8s/game-2048.yaml
- **What it is:** Sample workload (ns/deploy/svc/ALB ingress) synced by ArgoCD.

## multi-cluster-hub-spoke-argocd

### README.md
- **What it is:** Hub ArgoCD managing spoke clusters via workspaces.
- **Notable settings:** Workloads named `workloads-${env}`.

### hub/main.tf
- **What it is:** Hub EKS with ArgoCD + Pod Identity for cross-account assume.
- **Notable settings:** Name `hub-control-plane`; IAM role `argocd_hub`.

### hub/variables.tf / outputs.tf / versions.tf / destroy.sh / bootstrap/*
- **What they are:** Hub inputs/outputs; teardown; AppSets selecting non-control-plane clusters.

### spokes/main.tf
- **What it is:** Spoke EKS per workspace; registers cluster secret on hub (`install=false` on spoke Argo).
- **Notable settings:** Dual kubernetes providers (hub alias + spoke); remote state hub.

### spokes/workspaces/{dev,staging,prod}.tfvars
- **What they are:** Per-env CIDRs 10.1/10.2/10.3 and addon flags.

### spokes/deploy.sh / destroy.sh / .gitignore
- **What they are:** Workspace apply helpers; force-include tfvars.

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
