# EKS Blueprints Root Docs GitHub

```
need file inventory?
 → Root (README, license, tooling) → project identity + contribution gates
 → docs/ (MkDocs site) → what users learn and how patterns are published
 → .github/ (CI, templates, scripts) → how quality and publish are enforced
 unclear? → read file contents below by section
```

| Key point | Detail |
|---|---|
| What this is | Per-file catalog of non-image files under Root, `docs/`, and `.github/` in `terraform-aws-eks-blueprints-main` |
| Consumption model | Patterns are reference / copy-paste, not a Terraform module to consume as-is |
| Docs site | MkDocs Material; most pattern pages wrap `patterns/*/README.md` via `include-markdown` |
| CI focus | pre-commit, plan-examples, e2e apply/destroy, docs publish, link check, Scorecard, Dependabot |

## Summary

Amazon EKS Blueprints for Terraform is a pattern library (not an umbrella cluster module in v5). Root files define license, contribution, and local quality gates. `docs/` is the published MkDocs site (getting started, FAQ, migration, pattern pages, snippets). `.github/` owns issue/PR hygiene, workflows, and helper Python scripts for CI and docs build.

## Main content

## Root

### README.md

| Field | Detail |
|---|---|
| What it is | Project landing README for Amazon EKS Blueprints for Terraform |
| What it contains / does | Explains motivation (opinionated complete EKS clusters), consumption model (reference or copy-paste, not as a Terraform module), related projects (addon/addons/teams modules, GitOps, Data on EKS, Observability Accelerator, Karpenter Blueprints, GitLab CD component), Terraform caveats (bundled VPC, single-workspace + targeted apply, no module-style vars/outputs), support/feedback, security pointer, Apache-2.0 license |
| Why it matters | Primary onboarding and sets the non-module consumption contract |
| Notable details | Points to FAQ for kubernetes/helm/kubectl provider auth (static token vs `exec`); lists supporting modules `terraform-aws-eks-blueprint-addon(s)` and `terraform-aws-eks-blueprints-teams` |

### ADOPTERS.md

| Field | Detail |
|---|---|
| What it is | Self-reported adopters list |
| What it contains / does | Table of Organization, Description, Contacts, Link; invites PRs to add entries |
| Why it matters | Social proof and contact points for other implementers |
| Notable details | Alphabetical adopters include PITS Global Data Recovery Services, AlgoDx AB, Swyft Logistics; excluded from cspell in pre-commit |

### CODE_OF_CONDUCT.md

| Field | Detail |
|---|---|
| What it is | Code of conduct pointer |
| What it contains / does | Adopts Amazon Open Source Code of Conduct; FAQ link; `opensource-codeofconduct@amazon.com` |
| Why it matters | Community behavior baseline |
| Notable details | Thin wrapper; full text lives on aws.github.io |

### CONTRIBUTING.md

| Field | Detail |
|---|---|
| What it is | Contributing guidelines |
| What it contains / does | Bug/feature reporting tips; PR workflow (fork, focus change, tests, clear commits, watch CI); find `help wanted` issues; CoC; **security issues via AWS vulnerability page, not public GitHub issues**; licensing note |
| Why it matters | How external contributors interact safely and effectively |
| Notable details | Security path is explicit and non-negotiable for vulns |

### LICENSE

| Field | Detail |
|---|---|
| What it is | Full Apache License 2.0 text |
| What it contains / does | Standard Apache-2.0 terms (copyright/patent grants, redistribution, contribution terms, AS-IS warranty, liability) |
| Why it matters | Legal basis for use, redistribution, and contributions |
| Notable details | Matches README “Apache-2.0 Licensed” |

### NOTICE.txt

| Field | Detail |
|---|---|
| What it is | Apache NOTICE attribution file |
| What it contains / does | Copyright 2016–2022 Amazon.com, Inc. or affiliates; Apache-2.0 reference (`http://aws.amazon.com/apache2.0/`) |
| Why it matters | Required NOTICE companion under Apache-2.0 redistribution |
| Notable details | Short; copyright years end at 2022 while mkdocs copyright says 2024 |

### .gitignore

| Field | Detail |
|---|---|
| What it is | Git ignore rules |
| What it contains / does | Ignores IDE/OS junk, MkDocs `/site`, `.terraform`, lockfile, tfstate/tfplan, crash logs, `*.tfvars`, override tf files, terraformrc, `.tfsec`, `*.envrc`, `*kube-config.yaml`, `builds`, `__pycache__` |
| Why it matters | Keeps secrets, local state, and generated docs out of git |
| Notable details | Explicit comment that `.tfvars` often hold sensitive data |

### .pre-commit-config.yaml

| Field | Detail |
|---|---|
| What it is | Pre-commit hook config for local and CI quality |
| What it contains / does | Hooks: `cspell` (v9.0.1) with many path excludes; `pretty-format-yaml`; trailing whitespace / EOF / merge conflict / private key / AWS credentials; `pre-commit-terraform` (`terraform_fmt`, `terraform_docs`, `terraform_tflint` with selected rules, `terraform_validate` excluding `docs|modules`) |
| Why it matters | Enforces formatting, spelling, Terraform hygiene before merge |
| Notable details | TFLint limited to named rules only; validate skips `docs` and `modules` |

### cspell.config.yaml

| Field | Detail |
|---|---|
| What it is | CSpell dictionary wiring |
| What it contains / does | Defines `bpWords` dictionary from `./docs/cSpell_dict.txt` and enables it |
| Why it matters | Avoids false spellcheck failures on K8s/AWS jargon |
| Notable details | Companion word list lives under `docs/` even though config is at root |

### mkdocs.yml

| Field | Detail |
|---|---|
| What it is | MkDocs site configuration |
| What it contains / does | Site name Amazon EKS Blueprints for Terraform; Material theme (orange, Ember font, logos under `images/`); plugins `include-markdown`, `search`, `awesome-pages`; hook `.github/scripts/mkdocs-hooks.py`; `mike` version provider; markdown extensions (admonition, highlight, snippets, superfences, toc permalinks); docs from `docs/`; site URL `https://aws-ia.github.io/terraform-aws-eks-blueprints/` |
| Why it matters | Controls published documentation look, nav plugins, and build hooks |
| Notable details | Sticky nav tabs; copyright Amazon 2024 |

---

## docs

### docs/.pages

| Field | Detail |
|---|---|
| What it is | awesome-pages nav for docs root |
| What it contains / does | Order: Overview, Getting Started, Patterns, Snippets, v4 to v5 Migration, FAQ |
| Why it matters | Top-level docs navigation order |
| Notable details | Patterns/Snippets/v4-to-v5 are directories expanded by awesome-pages |

### docs/index.md

| Field | Detail |
|---|---|
| What it is | Docs home / Overview page |
| What it contains / does | Single `include-markdown` of `../README.md` |
| Why it matters | Keeps GitHub README and docs Overview in sync |
| Notable details | No extra body beyond the include |

### docs/getting-started.md

| Field | Detail |
|---|---|
| What it is | Getting started guide |
| What it contains / does | Prerequisites (awscli, kubectl, terraform); clone + `cd` into pattern; targeted apply VPC → EKS → full apply; `update-kubeconfig`; `kubectl get nodes`; destroy order (addons → eks → all); warnings for private clusters and resources created outside Terraform (e.g. Karpenter nodes) |
| Why it matters | Canonical first-run path for any pattern |
| Notable details | Points to Terraform Caveats for why targeted apply exists |

### docs/faq.md

| Field | Detail |
|---|---|
| What it is | Frequently asked questions |
| What it contains / does | Topics: VPC destroy timeouts (vpc-cni ENI leak cleanup order); leaked CloudWatch log groups (`create_cloudwatch_log_group` true/false tradeoffs); provider auth static token vs `exec()` with full HCL examples; stuck Terminating namespaces (orphan CRD resources, patch finalizers) |
| Why it matters | Day-2 failure modes users hit during apply/destroy |
| Notable details | Defaults examples to static tokens for ease; documents 15-minute token lifetime and `terraform refresh` |

### docs/cSpell_dict.txt

| Field | Detail |
|---|---|
| What it is | Custom spellcheck word list (~190 terms) |
| What it contains / does | Project jargon: agones, argocd, bottlerocket, karpenter, kubecost, irsa, efa, vllm, odcr, privatelink, etc. |
| Why it matters | Feeds `bpWords` for cspell so docs/patterns do not fail on domain terms |
| Notable details | Plain newline-separated words; referenced by root `cspell.config.yaml` |

### docs/_partials/destroy.md

| Field | Detail |
|---|---|
| What it is | Reusable destroy snippet |
| What it contains / does | Three `terraform destroy -target=...` commands (addons, eks, then all) plus link to getting-started destroy section |
| Why it matters | Shared teardown steps included by many pattern READMEs |
| Notable details | Included via `{% include-markdown %}` from pattern docs |

### docs/internal/ci.md

| Field | Detail |
|---|---|
| What it is | Internal CI setup notes for E2E |
| What it contains / does | Describes GitHub Actions using `configure-aws-credentials` + `setup-terraform`; CloudFormation for GitHub OIDC IAM role; attach `AdministratorAccess`; secret `ROLE_TO_ASSUME`; S3 backend for recoverability |
| Why it matters | How maintainers (or forks) wire AWS OIDC for e2e workflows |
| Notable details | Marked internal; not in top-level `.pages` nav (still in tree for maintainers) |

### docs/snippets/ipv4-prefix-delegation.md

| Field | Detail |
|---|---|
| What it is | Snippet: IPv4 prefix delegation on VPC CNI |
| What it contains / does | Explains raising pods-per-node; `before_compute = true` + `ENABLE_PREFIX_DELEGATION` / `WARM_PREFIX_TARGET`; verify via `kubectl describe ds aws-node` |
| Why it matters | Common IP density fix for dense workloads |
| Notable details | Warns wrong max-pods usually means CNI was not configured before nodes |

### docs/snippets/vpc-cni-custom-networking.md

| Field | Detail |
|---|---|
| What it is | Snippet: VPC CNI custom networking |
| What it contains / does | Secondary CIDRs, `AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG`, `ENIConfig` CRDs via `kubectl_manifest`, verification on aws-node env |
| Why it matters | Pattern for primary-CIDR exhaustion without redesigning the whole cluster |
| Notable details | Notes custom networking does not use primary ENI for pods (lower max pods) |

### docs/patterns/.pages

| Field | Detail |
|---|---|
| What it is | Patterns section nav |
| What it contains / does | Ordered list of pattern pages and subdirs (Auto Mode, GitOps, Machine Learning, Network, SSO variants, etc.) |
| Why it matters | Controls Patterns menu in published docs |
| Notable details | Titles differ slightly from some page front-matter titles |

### docs/v4-to-v5/.pages

| Field | Detail |
|---|---|
| What it is | Migration section nav |
| What it contains / does | Motivation → Cluster → Addons → Teams |
| Why it matters | Guides readers through v4→v5 migration docs |
| Notable details | Example TF lives under `example/` but is not listed in this `.pages` (linked from guides) |

### docs/v4-to-v5/motivation.md

| Field | Detail |
|---|---|
| What it is | Why v5 direction changed |
| What it contains / does | What worked (fast adoption, popular patterns); what failed (addon explosion, Terraform on-cluster limits, public API need, nested modules, competing cluster tools); v5 shifts to modular components + patterns-only repo; lists removals (cluster modules, KMS, EMR-on-EKS, irsa/helm-addon → addon module, teams → teams module, ArgoCD TF integration deferred); before/after repo trees |
| Why it matters | Explains why this repo is patterns, not an umbrella module |
| Notable details | Encourages `terraform-aws-eks` for cluster creation |

### docs/v4-to-v5/cluster.md

| Field | Detail |
|---|---|
| What it is | Cluster migration guide to EKS module v19.x |
| What it contains / does | Breaking changes (remove Blueprints cluster/KMS/EMR/teams modules); before (v4.32 `github.com/aws-ia/terraform-aws-eks-blueprints`) vs after (`terraform-aws-modules/eks/aws`) HCL; state/move guidance in longer body |
| Why it matters | Practical migration for cluster resources |
| Notable details | Points to `docs/v4-to-v5/example` for reference configs |

### docs/v4-to-v5/addons.md

| Field | Detail |
|---|---|
| What it is | Addons migration guide |
| What it contains / does | Marked under active development; skeleton before (`//modules/kubernetes-addons?ref=v4.32.1`) vs after (`aws-ia/eks-blueprints-addons/aws` `~> 1.0`); diff and placeholder state mv |
| Why it matters | Shows registry module path for addons in v5 |
| Notable details | Many sections still TODO placeholders |

### docs/v4-to-v5/teams.md

| Field | Detail |
|---|---|
| What it is | Teams migration guide |
| What it contains / does | Under active development; before embedded teams vs after `aws-ia/eks-blueprints-teams/aws` `~> 1.0`; diff + placeholder state mv |
| Why it matters | Points multi-tenancy users to standalone teams module |
| Notable details | TODO-heavy like addons guide |

### docs/v4-to-v5/example/README.md

| Field | Detail |
|---|---|
| What it is | Migration example folder title |
| What it contains / does | Single heading: `# Migration - v4 to v5` |
| Why it matters | Labels the companion TF example tree |
| Notable details | Minimal; real content is in `.tf` files |

### docs/v4-to-v5/example/main.tf

| Field | Detail |
|---|---|
| What it is | Shared supporting infra for migration example |
| What it contains / does | AWS provider, caller/AZ data, locals, VPC module (`~> 5.0`) with public/private subnets and k8s ELB tags |
| Why it matters | Common VPC used by v4 and v5 cluster examples |
| Notable details | Region hardcoded `us-west-2`; name `migration` |

### docs/v4-to-v5/example/v4.tf

| Field | Detail |
|---|---|
| What it is | Pre-migration (v4) cluster definition |
| What it contains / does | kubernetes provider with exec auth; `module.eks` from Blueprints `v4.32.1` with MNG, Fargate, self-managed NG, `map_roles` |
| Why it matters | Side-by-side “before” for migration |
| Notable details | Uses older output names like `eks_cluster_endpoint` / `eks_cluster_id` |

### docs/v4-to-v5/example/v5.tf

| Field | Detail |
|---|---|
| What it is | Post-migration (v5) cluster definition |
| What it contains / does | Same shape on `terraform-aws-modules/eks/aws` `~> 19.13` with `aws_auth_roles`, managed/fargate/self-managed groups, backwards-compat naming flags |
| Why it matters | Side-by-side “after” for migration |
| Notable details | Comments mark settings kept for backwards compatibility (IAM role names, KMS alias, log types) |

### docs/v4-to-v5/example/versions.tf

| Field | Detail |
|---|---|
| What it is | Terraform/provider version constraints for migration example |
| What it contains / does | TF `>= 1.0`; aws `>= 4.47`; kubernetes `>= 2.17` |
| Why it matters | Pins minimum tooling for the example |
| Notable details | No helm/kubectl providers declared here |

### Pattern docs pages (MkDocs wrappers)

Each file below is a short MkDocs page (YAML title + `include-markdown` of the pattern README). Content summarized is from the included README.

| Docs path | Included source | What the pattern is / does | Why it matters | Notable details |
|---|---|---|---|---|
| `patterns/agones-game-controller.md` | `patterns/agones-game-controller/README.md` | EKS + Agones for dedicated game servers; mentions GameLift FleetIQ | Gaming workload blueprint | Validate with sample gameserver + netcat UDP |
| `patterns/blue-green-upgrade.md` | `patterns/blue-green-upgrade/README.md` | Blue/green or canary migration across two EKS clusters via Route53 weighted routing, LBC, External DNS, ArgoCD apps-of-apps | Cluster cutover pattern | Stacks: environment, eks-blue, eks-green, shared module |
| `patterns/bottlerocket.md` | `patterns/bottlerocket/README.md` | Bottlerocket on MNG + Karpenter with Bottlerocket Update Operator for OS CVE patches | Hardened OS + automated patching | BRUPOP is patch-level only, not minor/major |
| `patterns/ecr-pull-through-cache.md` | `patterns/ecr-pull-through-cache/README.md` | ECR pull-through for Docker Hub, k8s, Quay, ECR; scan-on-push; addons use cached images | Faster/safer public image pulls | Needs `docker_secret` var for Docker Hub |
| `patterns/external-secrets.md` | `patterns/external-secrets/README.md` | External Secrets Operator with ClusterSecretStore/SecretStore (Secrets Manager + SSM) via IRSA | Secrets sync pattern | Includes `_partials/destroy.md` |
| `patterns/fargate-serverless.md` | `patterns/fargate-serverless/README.md` | Fully Fargate data plane; sample app; Fargate Fluent Bit logging ConfigMap | Serverless EKS dataplane | Validate Fargate node names + aws-logging CM |
| `patterns/fully-private-cluster.md` | `patterns/fully-private-cluster/README.md` | No internet; private endpoint; required VPC endpoints listed | Air-gapped / private-only clusters | Endpoint list includes ECR, STS, ELB, S3, etc. |
| `patterns/istio.md` | `patterns/istio/README.md` | EKS + Istio + ingress gateway (NLB); sample app; optional Kiali/Jaeger/Prometheus/Grafana | Service mesh starter | Requires ingress rollout restart due to istiod dependency issue |
| `patterns/karpenter.md` | `patterns/karpenter/README.md` | Karpenter controller on Fargate; includes highlighted TF/YAML from pattern files | Karpenter on serverless control nodes | Docs embed pattern `eks.tf` / `karpenter.tf` / yaml |
| `patterns/karpenter-mng.md` | `patterns/karpenter-mng/README.md` | Karpenter on tainted/labeled MNG; Pod Identity; SQS interruption queue | Karpenter with daemonset-friendly nodes | CoreDNS toleration avoids deadlock |
| `patterns/kubecost.md` | `patterns/kubecost/README.md` | Kubecost + AWS CUR billing integration; delayed CFN for crawler | Cost visibility on EKS | Needs `kubecost_token`; follow-up `run-me-in-24h/` |
| `patterns/multi-tenancy-with-teams.md` | `patterns/multi-tenancy-with-teams/README.md` | Teams isolation: team-red, team-blue, team-admin | Multi-tenant RBAC/namespace pattern | Validate section still TODO |
| `patterns/stateful.md` | `patterns/stateful/README.md` | Velero, EBS/EFS CSI, gp3 default SC, multi-volume + instance-store MNGs with CMK/gp3 | Stateful workload building blocks | Features optional; pick what you need |
| `patterns/sso-iam-identity-center.md` | `patterns/sso-iam-identity-center/README.md` | IAM Identity Center + EKS Access Entries/RBAC | AWS-native SSO into EKS | Uses `aws_ssoadmin_instances` data source |
| `patterns/sso-okta.md` | `patterns/sso-okta/README.md` | Okta OIDC IdP + Kubernetes RBAC | External IdP SSO | Uses kubectl oidc-login exec plugin |
| `patterns/eks-automode/eks-automode-custom-nodepools.md` | `patterns/eks-automode/automode-custom-nodepools/README.md` | EKS Auto Mode with custom NodeClass/NodePool (amd64/arm64/gpu); default pools disabled | Customize Auto Mode compute | YAML under `eks-automode-config/` |
| `patterns/gitops/gitops-getting-started-argocd.md` | `patterns/gitops/getting-started-argocd/README.md` | ArgoCD + GitOps Bridge (IaC metadata → Helm addons) | Intro GitOps on EKS | Optional fork of GitOps repos |
| `patterns/gitops/gitops-multi-cluster-hub-spoke-argocd.md` | `patterns/gitops/multi-cluster-hub-spoke-argocd/README.md` | Hub ArgoCD manages spoke clusters’ addons/workloads | Multi-cluster GitOps | Deploy hub then spokes; apps named `workloads-${env}` |
| `patterns/machine-learning/nvidia-gpu-efa.md` | `patterns/nvidia-gpu-efa/README.md` | `p5.48xlarge` + EFA + NVIDIA/EFA device plugins, RAID-0 NVMe | Multi-node GPU ML | Placement group + GPU taint/labels |
| `patterns/machine-learning/multi-node-vllm.md` | `patterns/multi-node-vllm/README.md` | Multi-node vLLM inference with LWS on `g6e.8xlarge` + EFA | Distributed inference | Includes Dockerfile for collective libs + ECR |
| `patterns/machine-learning/targeted-odcr.md` | `patterns/targeted-odcr/README.md` | Targeted ODCR via AZ-limited subnets, launch template capacity reservation, resource group | Guaranteed on-demand capacity | Screenshots copied into docs by mkdocs hook |
| `patterns/machine-learning/ml-container-cache.md` | `patterns/ml-container-cache/README.md` | Step Functions cache builder → EBS snapshot → mount at `/var/lib/containerd` | Faster large ML image starts | Claims ~5s vs ~6 min for large PyTorch image |
| `patterns/machine-learning/aws-neuron-efa.md` | `patterns/aws-neuron-efa/README.md` | `trn1.32xlarge` + Neuron + EFA plugins | Trainium/Inferentia-style ML | Neuron taint + RAID-0 NVMe |
| `patterns/machine-learning/ml-capacity-block.md` | `patterns/ml-capacity-block/README.md` | ML Capacity Block Reservation on MNG (`CAPACITY_BLOCK`) | Reserved ML capacity windows | AZ-restricted subnets + LT market options |
| `patterns/network/private-public-ingress.md` | `patterns/private-public-ingress/README.md` | Dual ingress-nginx (external + internal) with SG-backed NLBs | Split public/private ingress | Classes `ingress-nginx-external` / `ingress-nginx-internal` |
| `patterns/network/client-server-communication.md` | `patterns/vpc-lattice/client-server-communication/README.md` | VPC Lattice client↔server across VPCs via Gateway API Controller + external-dns | Service-to-service without classic peering complexity | Validate via Session Manager curl to `server.example.com` |
| `patterns/network/ipv6-eks-cluster.md` | `patterns/ipv6-eks-cluster/README.md` | IPv6 EKS networking | Dual-stack / IPv6 clusters | Pods/nodes show IPv6 addresses |
| `patterns/network/wireguard-with-cilium.md` | `patterns/wireguard-with-cilium/README.md` | Cilium chained with VPC CNI + WireGuard transparent encryption | Pod encryption overlay | Needs kernel 5.10+; NodeEncryption disabled in example |
| `patterns/network/privatelink-access.md` | `patterns/privatelink-access/README.md` | Access private EKS API via PrivateLink; SSM test from client EC2 | Private API access pattern | Targeted apply for eventbridge/nlb first |
| `patterns/network/aws-vpc-cni-network-policy.md` | `patterns/aws-vpc-cni-network-policy/README.md` | Native VPC CNI NetworkPolicy + Stars demo | NetworkPolicy without Calico/Cilium | Needs VPC CNI ≥ 1.14.0 |
| `patterns/network/cross-cluster-pod-communication.md` | `patterns/vpc-lattice/cross-cluster-pod-communication/README.md` | Secure multi-cluster Lattice with IAM auth, PCA TLS, Kyverno SigV4 sidecar, ExternalDNS | Cross-cluster with overlapping CIDRs | Blog-linked; bi-directional App1↔App2 |
| `patterns/network/tls-with-aws-pca-issuer.md` | `patterns/tls-with-aws-pca-issuer/README.md` | cert-manager + AWS Private CA issuer for TLS certs | Private PKI for cluster TLS | Validate Certificate Ready + TLS secret |

---

## .github

### .github/CODEOWNERS

| Field | Detail |
|---|---|
| What it is | CODEOWNERS file |
| What it contains / does | `* @aws-ia/internal-terraform-eks-admins` |
| Why it matters | Routes review ownership for all paths |
| Notable details | Single team owns everything |

### .github/dependabot.yml

| Field | Detail |
|---|---|
| What it is | Dependabot config |
| What it contains / does | Daily updates for `github-actions` ecosystem at `/` |
| Why it matters | Keeps Actions versions current |
| Notable details | Actions only (no npm/pip/terraform ecosystem entries here) |

### .github/PULL_REQUEST_TEMPLATE.md

| Field | Detail |
|---|---|
| What it is | PR description template |
| What it contains / does | Description; Motivation (`Resolves #`); test checklist (local test, docs update, `pre-commit run -a`); Additional Notes |
| Why it matters | Standardizes PR quality bar |
| Notable details | Warns to open an issue before significant work |

### .github/ISSUE_TEMPLATE/config.yml

| Field | Detail |
|---|---|
| What it is | Issue template config |
| What it contains / does | `blank_issues_enabled: false` |
| Why it matters | Forces structured issue forms |
| Notable details | No free-form blank issues |

### .github/ISSUE_TEMPLATE/bug_report.md

| Field | Detail |
|---|---|
| What it is | Bug report template |
| What it contains / does | Requires executable reproduction (`terraform init && apply`); search checkbox; cache clear steps; module/TF/provider versions; expected vs actual; screenshots |
| Why it matters | Makes bugs actionable for maintainers |
| Notable details | Mentions `examples/*` (historical naming; repo uses `patterns/`) |

### .github/ISSUE_TEMPLATE/feature_request.md

| Field | Detail |
|---|---|
| What it is | Feature request template |
| What it contains / does | Community Note (vote with reactions, no +1 noise); outcome, proposed solution, alternatives, context |
| Why it matters | Prioritizes features with signal, not comment spam |
| Notable details | Standard AWS terraform-module style community note |

### .github/ISSUE_TEMPLATE/question.md

| Field | Detail |
|---|---|
| What it is | Question issue template |
| What it contains / does | Search checkbox; question body; link to related example/module; context |
| Why it matters | Separates Q&A from bugs/features |
| Notable details | Asks for repo example link |

### .github/workflows/linkcheck.json

| Field | Detail |
|---|---|
| What it is | markdown-link-check config |
| What it contains / does | 5s timeout; retry on 429 (5×, 30s fallback); alive 200/206; special Accept-Encoding for help.github.com; ignore localhost/127.0.0.1 |
| Why it matters | Reduces flaky link CI failures |
| Notable details | Consumed by `markdown-link-check.yml` |

### .github/scripts/mkdocs-hooks.py

| Field | Detail |
|---|---|
| What it is | MkDocs build hook |
| What it contains / does | `on_page_markdown` (attempted path replaces; return markdown); `on_files` copies assets from pattern dirs into site (targeted-odcr screenshots, kubecost screenshot, ml-container-cache svg/png) |
| Why it matters | Makes pattern assets appear under docs URLs without duplicating into `docs/` |
| Notable details | `markdown.replace` results are not assigned back (no-op for markdown path rewrites) |

### .github/scripts/delete-log-groups.py

| Field | Detail |
|---|---|
| What it is | CI cleanup helper |
| What it contains / does | boto3 Logs client; deletes log groups prefixed `/aws/eks/` (up to 50 listed) in `AWS_DEFAULT_REGION` (default `us-west-2`) |
| Why it matters | Clears leaked EKS CW log groups before e2e runs |
| Notable details | Used by `e2e-parallel-full.yml` prereq job |

### .github/scripts/iam-policy-generator.py

| Field | Detail |
|---|---|
| What it is | IAM policy merger for e2e |
| What it contains / does | Reads all JSON policy objects from S3 bucket `BUCKET_NAME`; unions Action lists; prints Allow `Resource: "*"` skeleton policy |
| Why it matters | Builds aggregate IAM policy from iamlive captures across examples |
| Notable details | Needs `BUCKET_NAME` env; used post-deploy in e2e-full |

### .github/scripts/plan-examples.py

| Field | Detail |
|---|---|
| What it is | Discovers pattern directories for plan matrix |
| What it contains / does | Glob `patterns/**/main.tf`; exclude certain paths (appmesh-mtls, blue-green subdirs, istio-multi-cluster parts, privatelink-access); prints JSON array |
| Why it matters | Feeds `plan-examples.yml` matrix dynamically |
| Notable details | Skips paths matching `^.+/_` |

### .github/workflows/publish-docs.yml

| Field | Detail |
|---|---|
| What it is | Docs publish workflow |
| What it contains / does | On push to `main`: harden-runner; checkout; Python; pip install pinned mkdocs-material + include-markdown + awesome-pages; `mkdocs gh-deploy --force` |
| Why it matters | Publishes GitHub Pages docs site |
| Notable details | Pins plugin versions; contents write for gh-pages |

### .github/workflows/pre-commit.yml

| Field | Detail |
|---|---|
| What it is | Pre-commit CI on PRs |
| What it contains / does | Triggers on `**.tf`/`**.yml`/`**.yaml` to main; concurrency cancel; TF 1.3.10, terraform-docs v0.19.0, tflint v0.53.0; paths-filter for `*.tf`; composite pre-commit action when TF changed |
| Why it matters | Enforces same hooks as local pre-commit in CI |
| Notable details | Job name “Min TF pre-commit”; YAML-only changes may not run TF hooks if `src` filter false |

### .github/workflows/pr-title.yml

| Field | Detail |
|---|---|
| What it is | Semantic PR title validator |
| What it contains / does | `pull_request_target` opened/edited/synchronize; `amannn/action-semantic-pull-request`; subject must start uppercase; WIP allowed; no required scope |
| Why it matters | Keeps conventional/consistent PR titles |
| Notable details | Uses `pull_request_target` (runs in base context) |

### .github/workflows/plan-examples.yml

| Field | Detail |
|---|---|
| What it is | Manual terraform plan across patterns |
| What it contains / does | `workflow_dispatch` only; environment `EKS Blueprints Test`; only on `aws-ia/terraform-aws-eks-blueprints`; matrix from `plan-examples.py`; OIDC AWS us-west-2; terraform 1.0.0 init/plan per changed directory |
| Why it matters | Cheap validation that examples still plan |
| Notable details | Comments warn against checking out untrusted PR code for the python discovery step |

### .github/workflows/stale-issue-pr.yml

| Field | Detail |
|---|---|
| What it is | Stale issue/PR automation |
| What it contains / does | Daily cron + dispatch; stale after 30 days, close after 10 more; exempt `bug`/`enhancement`; custom messages |
| Why it matters | Keeps issue tracker from rotting |
| Notable details | Uses `actions/stale@main` |

### .github/workflows/e2e-parallel-full.yml

| Field | Detail |
|---|---|
| What it is | Full e2e apply/destroy matrix |
| What it contains / does | Manual dispatch with `TFDestroy` input (default true); prereq deletes `/aws/eks/` log groups; matrix of 7 patterns; uncomment remote backend; iamlive CSM capture; staged terraform apply/destroy targets; upload per-example policy JSON to S3; post job merges via `iam-policy-generator.py` |
| Why it matters | Real AWS validation of selected blueprints |
| Notable details | Patterns: agones, fargate, getting-started-argocd, ipv6, karpenter, multi-tenancy, stateful |

### .github/workflows/e2e-parallel-destroy.yml

| Field | Detail |
|---|---|
| What it is | Destroy-only e2e workflow |
| What it contains / does | Same pattern matrix as full e2e; OIDC; enable backend; staged destroy (addons → eks → all); no apply/iamlive |
| Why it matters | Cleanup stuck e2e state without re-applying |
| Notable details | Workflow name in file: `e2e-parallel-destroy-only` |

### .github/workflows/dependency-review.yml

| Field | Detail |
|---|---|
| What it is | PR dependency vulnerability review |
| What it contains / does | On pull_request; harden-runner; checkout; `dependency-review-action` (pinned SHAs) |
| Why it matters | Blocks known-vulnerable dependency bumps when required |
| Notable details | Comments explain required-check behavior |

### .github/workflows/scorecards.yml

| Field | Detail |
|---|---|
| What it is | OpenSSF Scorecard supply-chain analysis |
| What it contains / does | On branch protection, weekly Tuesday cron, push to main; scorecard-action SARIF; publish_results true; upload artifact + code scanning |
| Why it matters | Continuous supply-chain security score |
| Notable details | `permissions: read-all` default; security-events + id-token for upload/publish |

### .github/workflows/markdown-link-check.yml

| Field | Detail |
|---|---|
| What it is | Markdown link checker |
| What it contains / does | On push/PR to main when `**.md` changes; Node 20; `markdown-link-check@3.12.2`; runs on all `docs/**/*.md` with `linkcheck.json` |
| Why it matters | Prevents broken links in published docs |
| Notable details | Only scans `docs/`, not all repo markdown |

## Data flow map

```
Contributor / Maintainer
  │
  ├─ Root tooling
  │    README / LICENSE / NOTICE / CONTRIBUTING
  │    .pre-commit-config + cspell + .gitignore
  │
  ├─ docs/  ──mkdocs.yml + mkdocs-hooks.py──►  GitHub Pages
  │    index ← README
  │    getting-started / faq / snippets / v4-to-v5
  │    patterns/*.md ──include-markdown──► patterns/*/README.md
  │
  └─ .github/
       ISSUE/PR templates + CODEOWNERS + dependabot
       workflows:
         pre-commit / pr-title / link-check / dependency-review / scorecards
         publish-docs (main push)
         plan-examples (dispatch + plan-examples.py)
         e2e-full (delete-log-groups → apply+iamlive → S3 → iam-policy-generator)
         e2e-destroy (destroy only)
```

## Related files

| Path | Role |
|---|---|
| `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/` | Source tree documented |
| `patterns/*/` | Actual Terraform pattern code included by many `docs/patterns/*.md` pages |
| `3.sh` | Companion command list for browsing this inventory |

## Commands

See [`3.sh`](./3.sh).
