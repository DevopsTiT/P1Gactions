# SSO IAM Identity Center Pattern Files

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
| Scope | File-by-file deep dive for **SSO IAM Identity Center Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

### versions.tf
- **What it is:** aws + kubernetes providers.
- **What it contains:** No okta — uses AWS SSO APIs.
- **Why it matters:** Identity Center + Access Entries pattern.
- **Notable settings:** TF `>= 1.3`.

### variables.tf
- **What it is:** Admin/user Identity Store user configs.
- **What it contains:** family_name/given_name/email lists with defaults.
- **Why it matters:** Feeds `aws_identitystore_user` resources.
- **Notable settings:** Default example.com emails.

### main.tf
- **What it is:** EKS with API auth mode + Access Entries for SSO roles.
- **What it contains:** EKS `authentication_mode = "API"`; access entries for operators (ClusterAdminPolicy) and developers (ViewPolicy on default ns); VPC.
- **Why it matters:** Replaces aws-auth ConfigMap with Access Entries tied to SSO IAM roles.
- **Notable settings:**
  - `enable_cluster_creator_admin_permissions = true`
  - Developers also get `kubernetes_groups = ["eks-developers"]`
  - Principals from `data.aws_iam_roles.admin/user`

### sso.tf
- **What it is:** IAM Identity Center permission sets, users, groups, account assignments.
- **What it contains:** Permission sets EKSClusterAdmin/User; inline + managed policies; identitystore users/groups/memberships; account assignments.
- **Why it matters:** Creates IdP-side roles that Access Entries consume.
- **Notable settings:**
  - Session `PT1H`; PowerUserAccess / ViewOnlyAccess attachments
  - Groups `eks-operators` / `eks-developers`
  - Requires Identity Center enabled in account

### teams.tf
- **What it is:** Resolves reserved SSO IAM role ARNs + developers team namespace/RBAC via blueprints-teams.
- **What it contains:** `aws_iam_roles` name_regex for `AWSReservedSSO_EKSClusterAdmin_.*` / `User_.*`; `developers_team` module with quotas, limit ranges, network policy.
- **Why it matters:** Bridges SSO role ARNs into EKS access + namespace `development` isolation.
- **Notable settings:**
  - `create_iam_role = false`, `principal_arns = data.aws_iam_roles.user.arns`
  - NetworkPolicy ingress from default ns + 10.0.0.0/8 excepts

### outputs.tf
- **What it is:** kubectl + guided `aws configure sso` snippets for admin/user.
- **What it contains:** `configure_kubectl`, `configure_sso_admins`, `configure_sso_users`.
- **Why it matters:** End-user SSO profile setup after apply.
- **Notable settings:** Start URL uses identity store id + `.awsapps.com/start`.

### README.md
- **What it is:** Prerequisite Identity Center check; SSO configure examples; destroy order.
- **What it contains:** `aws identitystore list-instances`; password reset; destroy teams then eks then all.
- **Why it matters:** Documents Access Manager + SSO operational flow.
- **Notable settings:** May need re-associate ClusterAdminPolicy if creator access revoked before destroy.

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
