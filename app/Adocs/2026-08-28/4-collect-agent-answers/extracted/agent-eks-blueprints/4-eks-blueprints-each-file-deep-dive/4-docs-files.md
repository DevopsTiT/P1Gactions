# Docs Files Deep Dive

```
need to understand repo meta?
  README / CONTRIBUTING → how to consume and contribute
  docs/* → published site + FAQ + migration
  .github/* → CI, e2e, docs publish, issue templates
  unclear docs? → pattern README under patterns/ is source of truth
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Scope | File-by-file deep dive for **Docs Files Deep Dive** |
| Source | terraform-aws-eks-blueprints-main |

## Summary

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

## Data flow map

```
Root README (contract)
  → docs/ (MkDocs site includes README + pattern READMEs)
  → .github/workflows (plan / e2e / publish-docs)
  → patterns/ (actual runnable HCL)
```

## Related files

| File | Role |
|------|------|
| Index | `4-eks-blueprints-each-file-deep-dive.md` |
| Commands | `4.sh` |

## Commands

See [4.sh](4.sh).
