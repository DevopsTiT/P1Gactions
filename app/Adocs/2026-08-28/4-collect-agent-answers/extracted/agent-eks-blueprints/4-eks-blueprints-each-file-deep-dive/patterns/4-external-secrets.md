# External Secrets Pattern Files

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
| Scope | File-by-file deep dive for **External Secrets Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** Terraform/provider version constraints.
- **What it contains:** TF `>= 1.3`; aws; helm; `alekc/kubectl >= 2.0`.
- **Why it matters:** Enables kubectl manifests for ESO CRDs.
- **Notable settings:** Commented S3 backend for e2e.

### main.tf
- **What it is:** Full pattern: cluster, ESO, Secrets Manager + Parameter Store demos, IRSA.
- **What it contains:** Providers (aws/helm/kubectl); EKS; blueprints-addons with `enable_external_secrets`; KMS; ClusterSecretStore/SecretStore/ExternalSecrets; IAM roles/policies; EBS CSI IRSA.
- **Why it matters:** End-to-end External Secrets Operator wiring to AWS secret backends.
- **Notable settings:**
  - `enable_external_secrets = true`
  - ClusterSecretStore → SecretsManager; SecretStore → ParameterStore
  - Sample secrets username/password JSON
  - IRSA policies scoped to secret ARN / SSM path `/${local.name}/*`
  - Note: `secretstore_role` OIDC SA list uses `cluster_secretstore_sa` (same as cluster role), not `secretstore_sa`

### outputs.tf
- **What it is:** kubectl config helper.
- **What it contains:** `configure_kubectl` using region + cluster name.
- **Why it matters:** Post-apply access.
- **Notable settings:** `aws eks --region ${local.region} update-kubeconfig --name ...`

### README.md
- **What it is:** Short pattern overview + validate.
- **What it contains:** Deploy link; `kubectl get externalsecrets/secrets -n external-secrets`.
- **Why it matters:** Confirms both stores and secrets land in `external-secrets` ns.
- **Notable settings:** Namespace `external-secrets`.

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
