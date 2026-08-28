# SSO Okta Pattern Files

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
| Scope | File-by-file deep dive for **SSO Okta Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** aws + okta + kubernetes providers.
- **What it contains:** `okta/okta ~> 4.1.0`.
- **Why it matters:** Provisions IdP side + K8s RBAC bindings.
- **Notable settings:** TF `>= 1.3`.

### variables.tf
- **What it is:** Admin/developer user lists for Okta.
- **What it contains:** Objects with first/last/email; defaults for admin + 2 users.
- **Why it matters:** Drives Okta user/group membership creation.
- **Notable settings:** Default emails `@example.com`.

### main.tf
- **What it is:** EKS with Okta OIDC identity provider + VPC.
- **What it contains:** `cluster_identity_providers.okta` wired to Okta auth server/app; MNG; VPC.
- **Why it matters:** Connects EKS OIDC auth to Okta issuer/client.
- **Notable settings:**
  - `username_claim = "email"`, `groups_claim = "groups"`
  - issuer/client from `okta_auth_server.eks` / `okta_app_oauth.eks`
  - Cluster `1.30`

### okta.tf
- **What it is:** Okta IdP resources + K8s ClusterRoleBindings.
- **What it contains:** Okta provider placeholders; users/groups; OAuth app; auth server/claims/policy; RBAC for `eks-operators`→cluster-admin and `eks-developers`→view.
- **Why it matters:** Full SSO authN (Okta) + authZ (RBAC groups).
- **Notable settings:**
  - Groups claim filter `STARTS_WITH eks-`
  - App type native, PKCE, redirect `http://localhost:8000`
  - Provider placeholders `dev-<ORG_ID>` and `<OKTA_APU_TOKEN>`

### outputs.tf
- **What it is:** kubectl + oidc-login setup helpers.
- **What it contains:** `configure_kubectl`, `okta_login`, `configure_kubeconfig` exec-credential block.
- **Why it matters:** Client-side OIDC login wiring after apply.
- **Notable settings:** Uses `kubectl oidc-login` with issuer + client id.

### README.md
- **What it is:** Activate users, configure kubeconfig, role differences.
- **What it contains:** Browser auth flow; admin vs viewer groups.
- **Why it matters:** Operational SSO usage after Terraform.
- **Notable settings:** Mentions GuardDuty agents in sample output (illustrative).

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
