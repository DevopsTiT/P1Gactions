# EKS Blueprints Each File Deep Dive

```
want every file explained?
  start here (index) → pick area
  root / docs / .github → project contract + CI + published docs
  patterns/<name>.md → every file inside that pattern
  common file names? → see “Shared Terraform file roles” below
  deploy something? → 4.sh (review first)
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What you get | One markdown per area: root, docs, `.github`, and **each pattern** |
| How to use | Open the pattern md that matches `patterns/<folder>/` and read file-by-file |
| Source repo | `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main` |
| Not a module | Patterns are copy/reference examples, not Registry modules |

## Summary

This set explains **every important file** in Amazon EKS Blueprints for Terraform. Meta files (root, docs, CI) live in this folder. Pattern folders each have their own markdown under `patterns/`.

## Shared Terraform file roles

Most patterns reuse the same filenames. Learn these once:

| File | What it is | What it usually contains | Why you care |
|------|------------|--------------------------|--------------|
| `README.md` | Human guide | Intent, deploy, validate, destroy | Start here every time |
| `versions.tf` | Tooling floor | `required_version`, provider source/version | Avoid provider mismatch |
| `main.tf` | Bootstrap (sometimes whole stack) | Providers, locals, sometimes VPC+EKS+addons | Entry point for `terraform init` |
| `variables.tf` | Inputs | Only when pattern needs secrets/IDs (token, ODCR, Okta users) | What you must set before apply |
| `outputs.tf` | Helpful outputs | Usually `configure_kubectl`; sometimes SSO/IRSA/CUR | Copy-paste day-0 access |
| `vpc.tf` | Network | `terraform-aws-modules/vpc`; subnet tags for ELB/Karpenter | Wrong tags break LBs/Karpenter |
| `eks.tf` | Cluster | `terraform-aws-modules/eks`; MNG/Fargate/Auto Mode | Control plane + node shape |
| `addons.tf` | Day-2 software | `eks-blueprints-addons` and/or Helm | Controllers after cluster exists |
| `helm.tf` | Extra charts | Device plugins, Istio pieces, Neuron/NVIDIA/EFA | GPU/ML and mesh extras |
| `*.yaml` manifests | Runtime CRs / demos | NodePool, Ingress, GameServer, sample apps | Often applied **after** Terraform |
| `destroy.sh` | Safe teardown | Deletes AppSets/ALBs before `terraform destroy` | Prevents stuck VPC/ENI/NLB |

## Index — project meta

| Markdown | Covers |
|----------|--------|
| [4-root-files.md](4-root-files.md) | `README`, license, pre-commit, mkdocs, adopters, contributing |
| [4-docs-files.md](4-docs-files.md) | `docs/` getting-started, FAQ, snippets, v4→v5, every pattern doc page |
| [4-github-files.md](4-github-files.md) | Workflows, scripts, issue/PR templates, Dependabot, Scorecard |

## Index — patterns (one md each)

| Pattern folder | Deep dive md |
|----------------|--------------|
| `agones-game-controller` | [patterns/4-agones-game-controller.md](patterns/4-agones-game-controller.md) |
| `aws-neuron-efa` | [patterns/4-aws-neuron-efa.md](patterns/4-aws-neuron-efa.md) |
| `aws-vpc-cni-network-policy` | [patterns/4-aws-vpc-cni-network-policy.md](patterns/4-aws-vpc-cni-network-policy.md) |
| `blue-green-upgrade` | [patterns/4-blue-green-upgrade.md](patterns/4-blue-green-upgrade.md) |
| `bottlerocket` | [patterns/4-bottlerocket.md](patterns/4-bottlerocket.md) |
| `ecr-pull-through-cache` | [patterns/4-ecr-pull-through-cache.md](patterns/4-ecr-pull-through-cache.md) |
| `eks-automode` | [patterns/4-eks-automode.md](patterns/4-eks-automode.md) |
| `external-secrets` | [patterns/4-external-secrets.md](patterns/4-external-secrets.md) |
| `fargate-serverless` | [patterns/4-fargate-serverless.md](patterns/4-fargate-serverless.md) |
| `fully-private-cluster` | [patterns/4-fully-private-cluster.md](patterns/4-fully-private-cluster.md) |
| `gitops` | [patterns/4-gitops.md](patterns/4-gitops.md) |
| `ipv6-eks-cluster` | [patterns/4-ipv6-eks-cluster.md](patterns/4-ipv6-eks-cluster.md) |
| `istio` | [patterns/4-istio.md](patterns/4-istio.md) |
| `karpenter` | [patterns/4-karpenter.md](patterns/4-karpenter.md) |
| `karpenter-mng` | [patterns/4-karpenter-mng.md](patterns/4-karpenter-mng.md) |
| `kubecost` | [patterns/4-kubecost.md](patterns/4-kubecost.md) |
| `ml-capacity-block` | [patterns/4-ml-capacity-block.md](patterns/4-ml-capacity-block.md) |
| `ml-container-cache` | [patterns/4-ml-container-cache.md](patterns/4-ml-container-cache.md) |
| `multi-node-vllm` | [patterns/4-multi-node-vllm.md](patterns/4-multi-node-vllm.md) |
| `multi-tenancy-with-teams` | [patterns/4-multi-tenancy-with-teams.md](patterns/4-multi-tenancy-with-teams.md) |
| `nvidia-gpu-efa` | [patterns/4-nvidia-gpu-efa.md](patterns/4-nvidia-gpu-efa.md) |
| `private-public-ingress` | [patterns/4-private-public-ingress.md](patterns/4-private-public-ingress.md) |
| `privatelink-access` | [patterns/4-privatelink-access.md](patterns/4-privatelink-access.md) |
| `sso-iam-identity-center` | [patterns/4-sso-iam-identity-center.md](patterns/4-sso-iam-identity-center.md) |
| `sso-okta` | [patterns/4-sso-okta.md](patterns/4-sso-okta.md) |
| `stateful` | [patterns/4-stateful.md](patterns/4-stateful.md) |
| `targeted-odcr` | [patterns/4-targeted-odcr.md](patterns/4-targeted-odcr.md) |
| `tls-with-aws-pca-issuer` | [patterns/4-tls-with-aws-pca-issuer.md](patterns/4-tls-with-aws-pca-issuer.md) |
| `vpc-lattice` | [patterns/4-vpc-lattice.md](patterns/4-vpc-lattice.md) |
| `wireguard-with-cilium` | [patterns/4-wireguard-with-cilium.md](patterns/4-wireguard-with-cilium.md) |

## Suggested study order

```
1. 4-root-files.md + Shared table above
2. patterns/4-karpenter.md          (classic v5 shape)
3. patterns/4-fully-private-cluster.md
4. patterns/4-gitops.md             (GitOps Bridge)
5. patterns/4-blue-green-upgrade.md (lifecycle)
6. Then pick by need: GPU/ML, SSO, Lattice, Agones, Kubecost, ...
```

## Data flow map

```
You (reader)
  → index (this file)
      ├─ 4-root-files.md
      ├─ 4-docs-files.md
      ├─ 4-github-files.md
      └─ patterns/4-<pattern>.md
            → explains each file in patterns/<pattern>/
                 README → versions/main → vpc → eks → addons → yaml
```

Repo runtime flow (what the files create):

```
Terraform files in a pattern
  → VPC + EKS (+ IAM)
  → Helm / blueprints-addons / GitOps Bridge
  → Controllers + optional demo YAML
  → kubectl via outputs.configure_kubectl
```

## Related files

| File | Role |
|------|------|
| [4.sh](4.sh) | Example browse/deploy one-liners |
| Prior overview | `../1-eks-blueprints-deep-dive/` |
| Agent monoliths (optional) | `../3-eks-blueprints-patterns-file-dive/`, `../3-eks-blueprints-root-docs-github/` |

## Commands

All commands are in [4.sh](4.sh). Review before running; nothing is auto-executed for you.
