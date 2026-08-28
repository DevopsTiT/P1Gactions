# ECR Pull Through Cache Pattern Files

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
| Scope | File-by-file deep dive for **ECR Pull Through Cache Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** TF/providers/locals for pull-through cache pattern.
- **What it contains:** TF `>= 1.8`; aws/helm/kubernetes; account/AZ data; `cluster_version = "1.30"`.
- **Why it matters:** Shared locals (`name`, `region`, `ecr_url` used in addons).
- **Notable settings:** Region `us-west-2`.

### variables.tf
- **What it is:** Docker Hub credentials for authenticated pull-through.
- **What it contains:** Sensitive object `{username, accessToken}`.
- **Why it matters:** Required for docker-hub cache rule.
- **Notable settings:** Sensitive = true.

### vpc.tf
- **What it is:** Standard VPC module.
- **What it contains:** VPC `~> 5.9`, public/private, single NAT, ELB tags.
- **Why it matters:** Network for EKS nodes pulling via ECR.
- **Notable settings:** Private subnets for cluster.

### eks.tf
- **What it is:** EKS MNG with ECR pull-through IAM + EBS CSI IRSA + kubectl output.
- **What it contains:** EKS `~> 20.20`; IAM policy `ECRPullThroughCache`; node policies include that policy; ebs_csi_driver_irsa.
- **Why it matters:** Nodes can CreateRepository/BatchImportUpstreamImage for cache.
- **Notable settings:**
  - Policy actions: CreateRepository, BatchImportUpstreamImage, TagResource
  - Also `AmazonEC2ContainerRegistryReadOnly`
  - Addons: ebs-csi, coredns, kube-proxy, vpc-cni before_compute

### ecr.tf
- **What it is:** Secrets Manager docker secret + ECR registry pull-through rules + enhanced scanning.
- **What it contains:** secrets-manager module; ecr module with 4 rules (ecr/k8s/quay/dockerhub).
- **Why it matters:** Defines prefixes and upstream registries used by Helm image rewrites.
- **Notable settings:**
  - Prefixes: `ecr`, `k8s`, `quay`, `docker-hub`
  - dockerhub `credential_arn` from secret
  - `registry_scan_type = ENHANCED`, SCAN_ON_PUSH `*`

### addons.tf
- **What it is:** Blueprints addons + Gatekeeper with images rewritten to ECR cache URLs.
- **What it contains:** Argo CD, metrics-server, ALB controller, kube-prometheus-stack; separate gatekeeper addon module.
- **Why it matters:** Proves pull-through by forcing all chart images through account ECR prefixes.
- **Notable settings:**
  - `local.ecr_url = ACCOUNT.dkr.ecr.REGION.amazonaws.com`
  - Image repos under `/quay/...`, `/docker-hub/...`, `/k8s/...`, `/ecr/...`

### README.md
- **What it is:** Deploy with docker_secret var; validate cache rules; destroy ECR repos first.
- **What it contains:** `validate-pull-through-cache-rule` loop; pod list; mass ECR delete note.
- **Why it matters:** Cleanup guidance for auto-created cache repos.
- **Notable settings:** Apply var example for docker secret.

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
