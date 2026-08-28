# Stateful Pattern Files

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
| Scope | File-by-file deep dive for **Stateful Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** aws/helm/kubernetes providers.
- **What it contains:** Needed for storage classes + addons.
- **Why it matters:** Stateful storage CRDs managed by kubernetes provider.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Stateful-focused EKS: multi-volume + instance-store MNGs, Velero, EFS/EBS CSI, storage classes, KMS.
- **What it contains:** Two MNGs with custom block devices/user data; blueprints-addons; gp2 annotate / gp3+efs StorageClasses; S3 backup bucket; EFS; EBS KMS; EBS CSI IRSA.
- **Why it matters:** Reference for PV/storage best practices and node disk layout.
- **Notable settings:**
  - `multi-volume`: `/dev/xvdb` 24Gi gp3 encrypted; shell mounts containerd dirs
  - `instance-store`: `m5ad.large` + NodeConfig RAID0
  - Velero `s3_backup_location`; `enable_aws_efs_csi_driver`
  - gp3 default SC; efs SC `provisioningMode=efs-ap`
  - SSM policy on nodes for validation

### outputs.tf
- **What it is:** kubectl + Velero location outputs.
- **What it contains:** `configure_kubectl`, `velero_s3_backup_location`.
- **Why it matters:** Points operators at backup bucket path.
- **Notable settings:** Location = bucket ARN + `/backups`.

### README.md
- **What it is:** Feature guide for Velero, CSI, multi-volume, instance store.
- **What it contains:** Validate SC list, nvme-cli checks, velero CLI location.
- **Why it matters:** How to verify containerd on second volume and NVMe mounts.
- **Notable settings:** Expect `gp3 (default)`, `efs`, `gp2` present.

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
