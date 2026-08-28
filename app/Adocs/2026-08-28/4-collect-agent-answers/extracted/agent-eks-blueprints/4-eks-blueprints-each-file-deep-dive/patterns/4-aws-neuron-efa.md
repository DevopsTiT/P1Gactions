# AWS Neuron EFA Pattern Files

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
| Scope | File-by-file deep dive for **AWS Neuron EFA Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Terraform bootstrap for providers, locals, VPC, and kubectl helper output.
- **What it contains:** `aws` + `aws.ecr` (us-east-1) + `helm` providers; AZ data; VPC module `~> 5.0`; `configure_kubectl` output.
- **Why it matters:** Foundation for Neuron/EFA cluster; ECR alias needed for Public ECR Helm charts in `helm.tf`.
- **Notable settings:**
  - `region = "us-east-2"`
  - `vpc_cidr = "10.0.0.0/16"`, 3 AZs, single NAT
  - Helm auth via `aws eks get-token`

### eks.tf
- **What it is:** EKS cluster and managed node groups for Trainium + EFA.
- **What it contains:** `terraform-aws-modules/eks/aws` `~> 20.34`; addons; `neuron-efa` + `default` MNGs.
- **Why it matters:** Core of the pattern — Trainium nodes with EFA, placement, RAID0, taints/labels.
- **Notable settings:**
  - `cluster_version = "1.32"`, `enable_efa_support = true`
  - `ami_type = "AL2023_x86_64_NEURON"`, `trn1.32xlarge`, size 2/2/2
  - Labels `vpc.amazonaws.com/efa.present`, `aws.amazon.com/neuron.present`
  - Taint `aws.amazon.com/neuron=true:NoSchedule`
  - NodeConfig `localStorage.strategy: RAID0`

### helm.tf
- **What it is:** Device plugin Helm releases for Neuron and EFA.
- **What it contains:** Public ECR token data; `neuron-helm-chart` 1.1.1; `aws-efa-k8s-device-plugin` v0.5.7.
- **Why it matters:** Exposes Neuron devices and EFA NICs to pods that request them.
- **Notable settings:**
  - Neuron: `nodeSelector.aws.amazon.com/neuron.present`, `npd.enabled: false`
  - EFA: `nodeSelector.vpc.amazonaws.com/efa.present` + neuron toleration

### README.md
- **What it is:** Pattern docs (deploy/validate/destroy).
- **What it contains:** Architecture narrative; embed refs to `eks.tf`/`helm.tf`; kubectl validation sample.
- **Why it matters:** Explains why default MNG exists and why EFA is not separately tainted.
- **Notable settings:** Docs highlight EFA x8, placement group, RAID0, dual device plugins.

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
