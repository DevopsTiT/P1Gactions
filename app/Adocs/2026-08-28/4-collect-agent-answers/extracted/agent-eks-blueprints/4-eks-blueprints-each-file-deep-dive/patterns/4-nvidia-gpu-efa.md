# NVIDIA GPU EFA Pattern Files

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
| Scope | File-by-file deep dive for **NVIDIA GPU EFA Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Providers/VPC/output for NVIDIA+EFA pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for p5 GPU cluster.
- **Notable settings:** Standard VPC layout.

### eks.tf
- **What it is:** EKS with `p5.48xlarge` NVIDIA EFA MNG + default MNG.
- **What it contains:** Same shape as other GPU patterns: RAID0, EFA, labels, GPU taint.
- **Why it matters:** Hardware for NCCL/EFA MPIJob tests.
- **Notable settings:**
  - `AL2023_x86_64_NVIDIA`, `p5.48xlarge`, size 2
  - Cluster `1.32`, `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia 0.17.1; efa v0.5.7.
- **Why it matters:** Required before MPIJobs can request GPU/EFA resources.
- **Notable settings:** EFA tolerates `nvidia.com/gpu`.

### generate-efa-info-test.sh
- **What it is:** Bash generator for Kubeflow MPIJob that runs `fi_info -p efa`.
- **What it contains:** Env defaults (2 workers, 8 GPU, 32 EFA); writes `efa-info-test.yaml`.
- **Why it matters:** Validate EFA devices visible inside pods.
- **Notable settings:** Image `public.ecr.aws/hpc-cloud/nccl-tests:latest`; MPIJob v2beta1.

### generate-efa-nccl-test.sh
- **What it is:** Bash generator for NCCL all_reduce_perf MPIJob.
- **What it contains:** FI_/NCCL_ env; hugepages/memory requests; writes `efa-nccl-test.yaml`.
- **Why it matters:** Measure multi-node EFA bandwidth.
- **Notable settings:**
  - `INSTANCE_TYPE=p5e.48xlarge` (differs from eks.tf `p5.48xlarge`)
  - `EFA_PER_WORKER=32`, `GPU_PER_WORKER=8`
  - HostPath `/dev/shm`

### .gitignore
- **What it is:** Ignore generated MPIJob manifests.
- **What it contains:** `efa-info-test.yaml`, `efa-nccl-test.yaml`.
- **Why it matters:** Generated artifacts stay local.
- **Notable settings:** Two yaml filenames only.

### README.md
- **What it is:** Full validate path: MPI operator, info test, NCCL test, sample bandwidth logs.
- **What it contains:** Deploy MPI operator YAML; script usage; destroy.
- **Why it matters:** How to prove EFA/NCCL health on the cluster.
- **Notable settings:** Mentions optional ODCR block in eks.tf (commented in narrative).

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
