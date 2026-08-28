# TLS AWS PCA Issuer Pattern Files

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
| Scope | File-by-file deep dive for **TLS AWS PCA Issuer Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** aws/helm/kubectl constraints.
- **What it contains:** kubectl for AWSPCAClusterIssuer + Certificate CRDs.
- **Why it matters:** Works around kubernetes provider CRD issue (#1453).
- **Notable settings:** `alekc/kubectl >= 2.0`.

### variables.tf
- **What it is:** Certificate naming inputs.
- **What it contains:** `certificate_name` default `example`; `certificate_dns` default `example.com`.
- **Why it matters:** Feeds PCA subject CN and Certificate resource.
- **Notable settings:** Both strings with defaults.

### main.tf
- **What it is:** EKS + cert-manager + AWS Private CA issuer + sample Certificate.
- **What it contains:** Root ACM PCA + self-signed cert association; blueprints-addons (`enable_cert_manager`, `enable_aws_privateca_issuer`); cert-manager-csi-driver Helm; kubectl manifests.
- **Why it matters:** Private TLS issued into K8s Secret via PCA.
- **Notable settings:**
  - PCA: ROOT, RSA_4096, SHA512WITHRSA, validity 10 years
  - Issuer `AWSPCAClusterIssuer` named as cluster name
  - Certificate duration `2160h`, renewBefore `360h`, RSA 2048
  - Secret name `${certificate_name}-clusterissuer`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Validate Ready Certificate/Secret.
- **Notable settings:** Standard.

### README.md
- **What it is:** Validate PCA issuer pods and Certificate Ready state.
- **What it contains:** Expected secret `example-clusterissuer` type `kubernetes.io/tls`.
- **Why it matters:** Success criteria for TLS issuance.
- **Notable settings:** Namespaces `aws-privateca-issuer`, `cert-manager`.

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
