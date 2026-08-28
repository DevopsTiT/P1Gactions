# Multi Node VLLM Pattern Files

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
| Scope | File-by-file deep dive for **Multi Node VLLM Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Providers/locals/VPC for multi-node vLLM + LWS.
- **What it contains:** aws/helm/http/kubectl/local providers; region `us-east-2`; VPC.
- **Why it matters:** http+kubectl pull LWS manifests; local writes `build.sh`.
- **Notable settings:** TF providers include `hashicorp/http` and `alekc/kubectl`.

### eks.tf
- **What it is:** EKS with `g6e.8xlarge` EFA GPU MNG + default MNG.
- **What it contains:** EKS `~> 20.34`; EFA support; RAID0; GPU taint/labels; subnet pinned to 3rd private subnet.
- **Why it matters:** Hardware base for pipeline-parallel vLLM across nodes.
- **Notable settings:**
  - `ami_type = AL2023_x86_64_NVIDIA`, `g6e.8xlarge`
  - `subnet_ids = [element(private_subnets, 2)]`
  - Cluster `1.32`

### helm.tf
- **What it is:** Device plugins + LeaderWorkerSet install from GitHub release manifests.
- **What it contains:** nvidia/efa helm; `data.http` LWS v0.5.1 manifests applied via kubectl_manifest for_each.
- **Why it matters:** LWS CRD/controller required by `lws.yaml`.
- **Notable settings:** `lws_version = "v0.5.1"`, server_side_apply true.

### ecr.tf
- **What it is:** ECR repo + generated `build.sh` for image build/push and lws.yaml image sed.
- **What it contains:** ecr module; `local_file.vllm` bash script with zstd OCI build.
- **Why it matters:** Bridges Dockerfile → private ECR → LeaderWorkerSet image field.
- **Notable settings:** `repository_force_delete = true`; sed updates `./lws.yaml` image.

### lws.yaml
- **What it is:** vLLM LeaderWorkerSet + ClusterIP Service.
- **What it contains:** LWS size 4; leader OpenAI API server; workers ray_init; EFA/NCCL env; GPU+EFA resource requests.
- **Why it matters:** Workload definition for Llama-3.3-70B pipeline parallel.
- **Notable settings:**
  - `--pipeline-parallel-size 4`, `--tensor-parallel-size 1`
  - `FI_PROVIDER=efa`, HF token placeholder
  - Requests `nvidia.com/gpu: 1`, `vpc.amazonaws.com/efa: 1`, ephemeral-storage 160Gi

### Dockerfile
- **What it is:** Ubuntu 22.04 image with vLLM + EFA + NCCL + aws-ofi-nccl.
- **What it contains:** CUDA keyring; pip vllm; EFA installer 1.37.0; NCCL 2.25.1; aws-ofi-nccl 1.13.2-aws; ray_init.sh.
- **Why it matters:** Collective comms stack for multi-node GPU inference over EFA.
- **Notable settings:** CUDA 12.4; removes bundled NCCL; sm_89 gencode; hf_transfer.

### README.md
- **What it is:** End-to-end deploy/build/infer validate; quota warning for G/VT vCPUs.
- **What it contains:** build.sh timing note; HF token step; curl completion sample.
- **Why it matters:** Operational path after Terraform.
- **Notable settings:** Needs ≥64 vCPU G/VT quota for two g6e.8xlarge.

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
