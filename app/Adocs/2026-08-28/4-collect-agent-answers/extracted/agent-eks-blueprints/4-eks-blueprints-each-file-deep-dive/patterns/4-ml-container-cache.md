# ML Container Cache Pattern Files

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
| Scope | File-by-file deep dive for **ML Container Cache Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Guide for EBS-snapshot image cache for ML/GPU pods.
- **What it contains:** Step Functions cache builder, FSR, mount `/var/lib/containerd`, cached vs uncached timings.
- **Why it matters:** Explains why large PyTorch images start in seconds vs minutes.
- **Notable settings:** Apply `ebs_snapshot_builder` first; then full apply; `pod-cached.yaml` / `pod-uncached.yaml`.

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output.
- **What it contains:** aws+helm; VPC ~> 5.0 (3 AZs); `configure_kubectl`.
- **Why it matters:** Shared networking for cache builder + EKS.
- **Notable settings:** Region `us-west-2`; CIDR `10.0.0.0/16`.

### cache_builder.tf
- **What it is:** Module that builds EBS snapshots with pre-pulled images.
- **What it contains:** `clowdhaus/ebs-snapshot-builder/aws` ~> 1.1; public images list; FSR AZs.
- **Why it matters:** Writes snapshot ID to SSM used by the GPU node group.
- **Notable settings:** Caches `k8s-device-plugin:v0.17.1` and `pytorch:25.02-py3`.

### eks.tf
- **What it is:** EKS with GPU MNG mounting cached volume.
- **What it contains:** EKS ~> 20.34 (1.32); SSM snapshot data; GPU AL2 AMI + xvdb from snapshot; default MNG.
- **Why it matters:** Mounts cache under containerd so pulls are local.
- **Notable settings:** Device `xvdb` → `/var/lib/containerd`; label `ml-container-cache=true`; `g6e.xlarge`.

### helm.tf
- **What it is:** NVIDIA device plugin Helm release.
- **What it contains:** Chart 0.17.1 (matches cached image).
- **Why it matters:** Exposes GPUs on the GPU node group.

### pod-cached.yaml / pod-uncached.yaml
- **What they are:** Demo Pods for fast vs slow image pull contrast.
- **What they contain:** Same PyTorch image; cached has GPU nodeSelector/toleration + `IfNotPresent`.
- **Why they matter:** Prove cache value (~seconds vs minutes).

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
