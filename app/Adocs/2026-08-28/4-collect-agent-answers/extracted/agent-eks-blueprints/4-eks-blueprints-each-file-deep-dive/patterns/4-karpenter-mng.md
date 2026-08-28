# Karpenter MNG Pattern Files

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
| Scope | File-by-file deep dive for **Karpenter MNG Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### main.tf
- **What it is:** Same provider/local bootstrap as karpenter, name `ex-karpenter-mng`.
- **What it contains:** aws/ecr/helm; Public ECR token.
- **Why it matters:** OCI chart auth + shared tags.
- **Notable settings:** `local.name = "ex-${basename(path.cwd)}"`.

### vpc.tf
- **What it is:** VPC with discovery tags (same as karpenter).
- **What it contains:** Private subnet `karpenter.sh/discovery`.
- **Why it matters:** NodeClass subnet selection.
- **Notable settings:** Tag value = `local.name`.

### eks.tf
- **What it is:** EKS with tainted Bottlerocket MNG dedicated to Karpenter controller + CoreDNS tolerations.
- **What it contains:** MNG label/taint `karpenter.sh/controller`; CoreDNS toleration JSON; node SG discovery tags.
- **Why it matters:** Avoids deadlock (DNS must run before Karpenter can schedule elsewhere).
- **Notable settings:**
  - MNG `m5.large` Bottlerocket, desired 2
  - Taint NO_SCHEDULE on controller key
  - `node_security_group_tags` include discovery tag

### karpenter.tf
- **What it is:** Karpenter module with Pod Identity + Helm pinned to controller nodes.
- **What it contains:** `create_pod_identity_association = true`; helm nodeSelector/tolerations for controller taint.
- **Why it matters:** Contrast with Fargate pattern (IRSA vs pod identity).
- **Notable settings:**
  - Chart 1.0.2, webhook disabled
  - `nodeSelector.karpenter.sh/controller: 'true'`

### karpenter.yaml
- **What it is:** EC2NodeClass/NodePool for `ex-karpenter-mng`.
- **What it contains:** Same shape as karpenter pattern with role/discovery names updated.
- **Why it matters:** Applied post-TF for worker provisioning.
- **Notable settings:** role `ex-karpenter-mng`; discovery tags match.

### example.yaml
- **What it is:** Same inflate Deployment as karpenter.
- **What it contains:** pause, cpu 1, replicas 0.
- **Why it matters:** Demo scale-out onto Karpenter nodes.
- **Notable settings:** Identical to karpenter/example.yaml.

### README.md
- **What it is:** Explains MNG controller isolation + pod identity + SQS interruption queue.
- **What it contains:** Six-component narrative; validate/scale; destroy order.
- **Why it matters:** Why taint+label+CoreDNS toleration is required.
- **Notable settings:** Note README sample text says “four Fargate nodes” but pattern uses MNG (doc inconsistency).

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
