# Blue Green Upgrade Pattern Files

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
| Scope | File-by-file deep dive for **Blue Green Upgrade Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Blue/green or canary EKS migration via Route53 weights + ExternalDNS + ArgoCD.
- **What it contains:** Architecture, env → blue → green order, weight automation, teardown, troubleshooting.
- **Why it matters:** Platform-controlled traffic shift without app team CD changes.

### terraform.tfvars.example
- **What it is:** Shared variable template (region, zone, admin role, gitops SSH repos, secret name).

### tear-down-applications.sh / tear-down.sh
- **What they are:** Delete Argo apps/Ingress first; then targeted TF destroy for one cluster stack.
- **Why they matter:** Prevents orphan ALBs/DNS on destroy.

### environment/*
- **main.tf:** Shared VPC, sub Hosted Zone, ACM wildcard, ArgoCD admin secret.
- **variables/outputs/versions/README:** Shared infra API for both clusters.
- **Notable settings:** Subzone NS delegation; secret recovery_window 0.

### eks-blue/* and eks-green/*
- **What they are:** Thin wrappers calling `modules/eks_cluster`.
- **Blue:** service `blue`, k8s 1.26, weights **100**.
- **Green:** service `green`, k8s 1.27, weights **0**.
- **Why they matter:** Same module; traffic controlled by weight vars in metadata.

### bootstrap/addons.yaml / workloads.yaml
- **What they are:** AppSets embedded into cluster module (`file()`), injecting Route53 weights into Helm values.

### modules/eks_cluster/*
- **main.tf (~699 lines):** Locals/metadata; tag shared VPC subnets; EKS; platform/dev/ecsdemo teams; Git SSH secrets; gitops-bridge; blueprints addons metadata-only; vpc-cni/ebs IRSA.
- **Why it matters:** Reusable blue/green cluster definition.
- **Notable addons:** cert-manager, ExternalDNS, ExternalSecrets, LBC, Fluent Bit, Karpenter, ingress-nginx, kyverno, metrics-server.

### static/*.png
- Architecture screenshots only (skipped in deep dive).

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
