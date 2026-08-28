# Karpenter Fargate Pattern Files

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
| Scope | File-by-file deep dive for **Karpenter Fargate Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Providers/locals for Karpenter-on-Fargate pattern.
- **What it contains:** aws + aws.ecr + helm; Public ECR token; name `ex-${basename(path.cwd)}`.
- **Why it matters:** Public ECR auth for Karpenter OCI chart.
- **Notable settings:** `region = us-west-2`.

### vpc.tf
- **What it is:** VPC with Karpenter discovery tags on private subnets.
- **What it contains:** VPC module; `karpenter.sh/discovery = local.name` on private subnets.
- **Why it matters:** Subnet auto-discovery for EC2NodeClass.
- **Notable settings:** Discovery tag must match NodeClass selectors.

### eks.tf
- **What it is:** Fargate-backed EKS (Karpenter controller namespace) without classic node SGs.
- **What it contains:** Fargate profile for `karpenter` ns; CoreDNS commented; pod-identity-agent/kube-proxy/vpc-cni; cluster tagged for discovery.
- **Why it matters:** Controller runs on Fargate; worker EC2 comes from Karpenter later.
- **Notable settings:**
  - `create_cluster_security_group/create_node_security_group = false`
  - Tag `karpenter.sh/discovery = local.name` on cluster

### karpenter.tf
- **What it is:** Karpenter IAM/SQS module + Helm install with IRSA (no pod identity).
- **What it contains:** `eks//modules/karpenter` `~> 20.24`; helm_release Karpenter 1.0.2.
- **Why it matters:** Fargate cannot use pod identity — IRSA enabled instead.
- **Notable settings:**
  - `enable_v1_permissions = true`
  - `create_pod_identity_association = false`, `enable_irsa = true`
  - `node_iam_role_name = local.name` (matches EC2NodeClass role)
  - `dnsPolicy: Default`, webhook disabled

### karpenter.yaml
- **What it is:** Manual EC2NodeClass + NodePool (apply after TF).
- **What it contains:** Bottlerocket AMI alias; role `ex-karpenter`; discovery selectors; NodePool instance constraints.
- **Why it matters:** Runtime Karpenter config not applied by Terraform.
- **Notable settings:**
  - categories c/m/r; cpu 4/8/16/32; nitro; generation > 2
  - `consolidationPolicy: WhenEmpty`, `consolidateAfter: 30s`, cpu limit 1000

### example.yaml
- **What it is:** Inflate Deployment to trigger provisioning.
- **What it contains:** pause image, replicas 0, cpu request 1.
- **Why it matters:** Scale to 3 to demo Karpenter node creation.
- **Notable settings:** `replicas: 0` initially.

### README.md
- **What it is:** Fargate Karpenter walkthrough + destroy order.
- **What it contains:** Apply yaml → scale inflate → expect EC2 nodes; destroy example then helm target.
- **Why it matters:** Correct teardown order avoids stuck nodes.
- **Notable settings:** Destroy targets `helm_release.karpenter` first after deleting example.

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
