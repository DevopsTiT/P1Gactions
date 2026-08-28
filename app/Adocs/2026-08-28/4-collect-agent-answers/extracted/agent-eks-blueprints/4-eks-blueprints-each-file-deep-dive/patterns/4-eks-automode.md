# EKS Auto Mode Pattern Files

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
| Scope | File-by-file deep dive for **EKS Auto Mode Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### Note
- In this checkout, `patterns/eks-automode/` only contains `automode-custom-nodepools/` (no sibling root pattern).

### automode-custom-nodepools/README.md
- **What it is:** Pattern doc for Auto Mode with custom NodeClass/NodePool.
- **What it contains:** Disables built-in pools; amd64/graviton examples; EBS + ALB class; sample app validate/destroy.
- **Why it matters:** Shows how to segregate compute under Auto Mode.

### automode-custom-nodepools/main.tf
- **What it is:** VPC + Auto Mode EKS + custom node IAM role.
- **What it contains:** EKS ~> 20.34 (1.31, `us-east-1`); `cluster_compute_config.enabled=true`, `node_pools=[]`; Access Entry AutoNodePolicy; IAM WorkerNodeMinimal + ECR.
- **Why it matters:** Foundation for custom NodeClasses referencing that role.

### automode-custom-nodepools/eks-automode-config.tf
- **What it is:** Applies YAML manifests via kubectl provider.
- **What it contains:** for_each for storageclass, ingressclass, nodeclass (templated), nodepool.
- **Why it matters:** Bridges Terraform IAM/cluster to Auto Mode CRs.

### eks-automode-config/ebs-storageclass.yaml
- **What it is:** Default StorageClass for Auto Mode EBS CSI (`auto-ebs-sc`, gp3, encrypted).

### eks-automode-config/alb-ingressclass.yaml + alb-ingressclassParams.yaml
- **What they are:** Default ALB IngressClass + internet-facing params for Auto Mode LBC.

### eks-automode-config/nodeclass-basic.yaml / nodeclass-ebs-optimized.yaml
- **What they are:** Auto Mode NodeClasses (80Gi vs 100Gi/5000 IOPS ephemeral profiles).

### eks-automode-config/nodepool-amd64.yaml / nodepool-graviton.yaml
- **What they are:** Karpenter v1 NodePools for amd64 vs arm64 with taints/labels and cpu limit 1000.

### automode-custom-nodepools/sample-app.yaml
- **What it is:** httpd StatefulSet + Service + ALB Ingress demo on amd64 + `auto-ebs-sc`.

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
