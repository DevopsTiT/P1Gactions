# EKS Blueprints Deep Dive

```
need EKS fast + opinionated?
  copy a pattern? → clone repo → cd patterns/<name> → targeted apply
  reuse as module? → NO — patterns are examples, not modules
  only need cluster? → terraform-aws-eks module directly
  only need addons? → terraform-aws-eks-blueprints-addons
  only need teams/tenancy? → terraform-aws-eks-blueprints-teams
  data workloads? → data-on-eks (sibling project)
  GitOps addons? → patterns/gitops + GitOps Bridge
  destroy stuck? → delete workloads → destroy addons → eks → vpc
  401 on apply? → refresh token or switch to exec() auth
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What this repo is | A catalog of tested EKS **patterns** (examples), not a Terraform module you call with `source =` |
| What problem it solves | Building a complete EKS cluster with networking, IAM, and operational software takes weeks; blueprints shrink that to days |
| How you use it | Reference the HCL, or copy-paste a pattern and customize locally |
| v5 model | Cluster = `terraform-aws-eks`; addons/teams live in sibling repos; this repo holds patterns only |
| Deploy order | VPC first → EKS second → everything else (targeted `apply`) |
| Destroy order | Workloads/Karpenter nodes first → addons → EKS → VPC |

## Summary

Amazon EKS Blueprints for Terraform is an AWS Solution Architect–maintained collection of ready-to-run EKS cluster recipes. Each folder under `patterns/` shows a full architecture (VPC + EKS + addons + demo pieces) for a specific goal: Karpenter, private clusters, GitOps, GPU/ML, multi-tenancy, and more. You learn from the code or copy it; you do not consume the whole project as one reusable module.

---

## 1. What this is (plain English)

**Amazon EKS** is AWS’s managed Kubernetes control plane. You still must choose networking, node compute, IAM for pods, ingress, secrets, autoscaling, and day-2 tooling.

**EKS Blueprints** answers: “Show me a working, opinionated setup for *this* use case.”

| Term | What it means | Why you care |
|------|---------------|--------------|
| Pattern / blueprint | A complete Terraform example under `patterns/` | Copy or study; deployable as-is for learning |
| Snippet | Smaller reusable idea inside a pattern | Steal pieces (IRSA, subnet tags, Helm values) |
| Supporting module | Separate GitHub/Terraform Registry module | Real reusable building blocks (addons, teams, single addon) |
| Add-on | Software on the cluster (CoreDNS, ALB controller, Karpenter, Argo CD) | Makes the cluster usable for real workloads |

Analogy: Blueprints is a **cookbook** of full meals. The Registry modules are the **ingredients**. Your production repo is the **restaurant kitchen** that adapts recipes.

---

## 2. Why it exists (motivation)

Kubernetes is powerful but choice-heavy. Teams burn months integrating CNI, ingress, autoscaling, secrets, GitOps, and AWS IAM.

Customers asked AWS for **purpose-built, complete clusters** so they can onboard workloads in **days, not months**. Blueprints ships those recipes with testing and docs.

| Without blueprints | With blueprints |
|--------------------|-----------------|
| Design VPC tags for ALB/Karpenter yourself | Pattern already tags subnets correctly |
| Wire OIDC/IRSA for every Helm chart | Addons module / pattern shows the wiring |
| Discover private-cluster VPC endpoints by trial | Fully-private pattern lists required endpoints |
| Guess destroy order and leak ENIs | Docs + pattern READMEs give ordered teardown |

---

## 3. How you are supposed to consume it

There are **two** supported ways:

| Mode | What you do | When to use |
|------|-------------|-------------|
| Reference | Read the pattern; recreate the same ideas in your own Terraform | You already have VPC/cluster standards |
| Copy & paste | Clone, `cd patterns/<name>`, change locals (name, region, CIDR), apply | Learning, PoC, starting point for a new platform |

**Not supported:** treating this repo’s patterns as a Terraform module (`module "blueprints" { source = "..." }`).

Why:

- Patterns barely expose `variables` / `outputs` on purpose
- They use `locals` for name, region, CIDR so examples stay simple
- Publishing them as modules would confuse “example” vs “library”

If you need a different region or cluster name: **edit the pattern locally**, then apply.

---

## 4. Repo layout (what lives where)

```
terraform-aws-eks-blueprints-main/
├── README.md                 # Project pitch, consumption, caveats, related projects
├── docs/                     # MkDocs site source (getting-started, FAQ, v4→v5, pattern pages)
│   ├── getting-started.md
│   ├── faq.md
│   ├── v4-to-v5/             # Migration story and examples
│   └── patterns/             # Doc mirrors of many patterns
├── patterns/                 # ★ All runnable blueprints live here
│   ├── karpenter/
│   ├── fully-private-cluster/
│   ├── gitops/
│   └── ... (~30 pattern areas)
├── .github/                  # CI: plan-examples, e2e, docs publish, pre-commit
└── mkdocs.yml                # Docs site config
```

Important mental model for **v5**:

| Location | Contains modules? | Role |
|----------|-------------------|------|
| This repo (`terraform-aws-eks-blueprints`) | No (patterns only) | Recipes and architecture guidance |
| `terraform-aws-eks` (community) | Yes | Create the EKS cluster |
| `terraform-aws-eks-blueprints-addon` | Yes | One Helm addon + IRSA |
| `terraform-aws-eks-blueprints-addons` | Yes | Bundle of EKS + Helm addons |
| `terraform-aws-eks-blueprints-teams` | Yes | Multi-tenancy (namespaces, RBAC, quotas) |

---

## 5. v4 → v5: the big architectural shift

### What worked in early Blueprints

- Got teams from zero to running clusters quickly (often under 1–2 weeks)
- Popular recipes: Spark on EKS, Karpenter on Fargate, WireGuard+Cilium encryption, serverless Fargate

### What did not scale

| Pain | Why it hurt |
|------|-------------|
| Too many addon variants | CNCF landscape is huge; each chart has many install shapes |
| Terraform managing in-cluster objects | Dependency order fails easily; Terraform does not continuously reconcile like a controller |
| Public API endpoint often required | Terraform “pushes” from outside the VPC |
| Nesting Helm wrappers as modules | Bottleneck to review/test every chart; versioning gets muddy |
| Duplicate cluster modules | `terraform-aws-eks` already existed and Blueprints already used it under the hood |

### What v5 changed

1. **Removed** Blueprints’ own cluster / node-group / Fargate / launch-template / KMS / IRSA / helm-addon / teams / EMR modules from this repo
2. **Point users** at `terraform-aws-eks` for cluster creation
3. **Spin out** addons and teams to dedicated repos
4. **Keep this repo** as the canonical pattern library
5. Prefer **GitOps pull** for many in-cluster installs (Argo CD / GitOps Bridge) over pushing everything from Terraform

### Blueprint vs usage reference

| Type | Focus | Where it lives |
|------|-------|----------------|
| Blueprint | Holistic architecture: security, ops, observability, day-2 | This repo’s `patterns/` |
| Usage reference | “How do I pass this Helm value?” | Addons / Karpenter / other implementation repos |

---

## 6. Related projects (ecosystem map)

| Project | What it is | When you reach for it |
|---------|------------|------------------------|
| [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks) | Community EKS module | Create control plane, MNG, Fargate, Karpenter IAM helpers |
| [terraform-aws-eks-blueprints-addon](https://github.com/aws-ia/terraform-aws-eks-blueprints-addon) | Single Helm release + IRSA | Build one custom addon the Blueprints way |
| [terraform-aws-eks-blueprints-addons](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons) | Many addons together | AWS LB Controller, ExternalDNS, metrics-server, etc. |
| [terraform-aws-eks-blueprints-teams](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) | Multi-tenancy | Isolate team namespaces and access |
| [terraform-aws-eks-ack-addons](https://github.com/aws-ia/terraform-aws-eks-ack-addons) | ACK controllers on EKS | Manage AWS resources from Kubernetes |
| [crossplane-on-eks](https://github.com/awslabs/crossplane-on-eks) | Crossplane compositions | Provision cloud via K8s XR/XRD |
| [data-on-eks](https://github.com/awslabs/data-on-eks) | Data/AI blueprints | Spark, Ray, Airflow-style data planes |
| [terraform-aws-observability-accelerator](https://github.com/aws-observability/terraform-aws-observability-accelerator) | AMP / AMG / ADOT | Managed observability stack |
| [karpenter-blueprints](https://github.com/aws-samples/karpenter-blueprints) | Karpenter workload scenarios | Deeper NodePool/EC2NodeClass designs |
| GitOps Bridge | IaC metadata → Argo CD | Terraform creates cloud IAM; Argo installs charts |

---

## 7. Step-by-step: deploy any typical pattern

Prerequisites on your laptop:

| Tool | Role |
|------|------|
| `awscli` | Auth to AWS; `eks update-kubeconfig`; (optional) `get-token` for providers |
| `kubectl` | Talk to the cluster after create |
| `terraform` | Plan/apply the pattern |

### Step A — Choose and enter a pattern

```
clone repo → cd patterns/<pattern-name>
```

Example: `patterns/karpenter` for Karpenter on Fargate.

### Step B — Understand the file split (common shape)

Most patterns look like this:

| File | Job |
|------|-----|
| `main.tf` | Providers, versions, `locals` (name, region, CIDR, tags) |
| `vpc.tf` | `terraform-aws-modules/vpc/aws` + subnet tags for ELB/Karpenter |
| `eks.tf` | `terraform-aws-modules/eks/aws` cluster + node/Fargate config |
| `addons.tf` / `karpenter.tf` | Helm releases, blueprints-addons, extra AWS resources |
| `outputs.tf` | Often `configure_kubectl` command |
| `README.md` | Pattern intent, validate steps, destroy notes |

### Step C — Targeted apply (why, then how)

HashiCorp recommends **not** putting computed values into provider blocks. Blueprints still puts `kubernetes` / `helm` / `kubectl` providers in the **same** workspace as the cluster so learners get one folder that works.

To make that safe enough in practice, deploy in stages:

1. Create VPC (network exists)
2. Create EKS (API endpoint + auth exist)
3. Apply the rest (Helm/addons can talk to the API)

See companion commands in [1.sh](1.sh).

### Step D — Wire kubectl

Use the Terraform output (most patterns print something like):

```
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>
```

Then: `kubectl get nodes`.

**Private clusters:** public endpoint may be off. You must reach the API from inside the VPC (bastion / SSM / PrivateLink pattern). Follow that pattern’s README.

### Step E — Validate

Pattern READMEs usually include:

- `kubectl get nodes`
- `kubectl get pods -A`
- A demo scale-up (for Karpenter: apply `NodePool`, scale a Deployment)

---

## 8. Step-by-step: destroy safely

Wrong destroy order leaves ENIs, security groups, or Karpenter EC2 instances behind.

Recommended flow:

```
1. Delete demo workloads / scale to 0 (esp. Karpenter-created nodes)
2. terraform destroy -target=module.eks_blueprints_addons  (or Helm releases)
3. terraform destroy -target=module.eks
4. terraform destroy   # VPC and leftovers
```

| Risk | What goes wrong | Mitigation |
|------|-----------------|------------|
| Karpenter nodes | Terraform never created those EC2s | Delete apps / NodePools before destroy |
| VPC CNI ENI leak | Subnets/SGs cannot delete | Drain pods → wait → remove CNI-related resources → nodes → cluster |
| Namespace Terminating | Finalizers / orphaned CRDs | List namespaced resources; clear finalizers carefully |
| CloudWatch log group | EKS service recreates log group after TF deletes it | Let EKS own the log group, or delete manually before recreate |

---

## 9. Anatomy deep dive: Karpenter-on-Fargate pattern

This is the textbook v5 pattern. Walk it once and you understand most others.

### Layer 1 — Locals and providers (`main.tf`)

- `local.name` from folder basename (`ex-karpenter`)
- Default region often `us-west-2`
- AWS provider + **alias** `aws.ecr` in `us-east-1` (ECR Public auth for Karpenter chart)
- Helm provider uses `exec { aws eks get-token ... }` against the new cluster

### Layer 2 — VPC (`vpc.tf`)

| Setting | Meaning |
|---------|---------|
| Private + public subnets | Nodes private; NAT for egress; public for internet-facing LBs |
| `kubernetes.io/role/elb = 1` on public | AWS LB Controller finds public subnets |
| `kubernetes.io/role/internal-elb = 1` on private | Internal LBs land correctly |
| `karpenter.sh/discovery = <cluster>` on private | Karpenter discovers which subnets to launch into |
| `single_nat_gateway = true` | Cheaper for demos (not HA prod) |

### Layer 3 — EKS (`eks.tf`)

| Setting | Meaning |
|---------|---------|
| `terraform-aws-modules/eks/aws` ~> 20.x | Official community module |
| `enable_cluster_creator_admin_permissions` | Terraform identity can install Helm |
| `cluster_endpoint_public_access = true` | Laptop Terraform can reach API (demo tradeoff) |
| Fargate profile for `karpenter` namespace | Controller runs serverless; no bootstrap EC2 required |
| CoreDNS often deferred | Comment notes enable after Karpenter nodes exist |
| Tag `karpenter.sh/discovery` on cluster | Discovery for security groups |

### Layer 4 — Karpenter AWS + Helm (`karpenter.tf`)

1. `module "karpenter"` (submodule of terraform-aws-eks): IAM roles, SQS interruption queue, EventBridge
2. `helm_release.karpenter`: chart from `public.ecr.aws/karpenter`, IRSA annotation on ServiceAccount
3. You apply `karpenter.yaml` (`EC2NodeClass` + `NodePool`) after cluster is up
4. Scale a sample Deployment → Karpenter launches EC2 → pods schedule

### Data path for a pending pod (this pattern)

```
Pending pod
  → kube-scheduler cannot place (no EC2 yet)
  → Karpenter watches unschedulable pods
  → matches NodePool requirements
  → EC2NodeClass → RunInstances in tagged private subnets
  → node joins cluster
  → pod binds and runs
  → scale to 0 → Karpenter terminates empty node
```

---

## 10. Complete pattern catalog (grouped)

### Compute and autoscaling

| Pattern folder | What it teaches |
|----------------|-----------------|
| `karpenter` | Karpenter controller on **Fargate**; EC2 nodes on demand |
| `karpenter-mng` | Karpenter alongside **managed node groups** |
| `fargate-serverless` | Fully serverless data plane + Fargate logging |
| `bottlerocket` | Bottlerocket OS + Bottlerocket Update Operator + Karpenter resources |
| `eks-automode` | EKS Auto Mode / custom node pools |
| `targeted-odcr` | On-Demand Capacity Reservations targeting |
| `ml-capacity-block` | ML Capacity Block Reservation |

### Networking and connectivity

| Pattern folder | What it teaches |
|----------------|-----------------|
| `fully-private-cluster` | No internet; required VPC interface/gateway endpoints |
| `privatelink-access` | Reach private EKS API via PrivateLink |
| `private-public-ingress` | Mix of private and public ingress |
| `ipv6-eks-cluster` | Dual-stack / IPv6 cluster networking |
| `aws-vpc-cni-network-policy` | NetworkPolicy with VPC CNI |
| `wireguard-with-cilium` | Transparent encryption (Cilium + WireGuard) |
| `vpc-lattice` | VPC Lattice client/server and cross-cluster pod communication |
| `istio` | Service mesh on EKS |

### Security, identity, secrets, TLS

| Pattern folder | What it teaches |
|----------------|-----------------|
| `external-secrets` | External Secrets Operator pulling from AWS |
| `tls-with-aws-pca-issuer` | cert-manager + AWS Private CA issuer |
| `sso-iam-identity-center` | IAM Identity Center SSO + Cluster Access Manager |
| `sso-okta` | Okta SSO into EKS |
| `multi-tenancy-with-teams` | `team-red` / `team-blue` / admin isolation via teams module |
| `ecr-pull-through-cache` | ECR pull-through cache for upstream registries |

### GitOps and cluster lifecycle

| Pattern folder | What it teaches |
|----------------|-----------------|
| `gitops/getting-started-argocd` | GitOps Bridge: Terraform metadata → Argo CD ApplicationSets |
| `gitops/multi-cluster-hub-spoke-argocd` | Hub-and-spoke multi-cluster Argo CD |
| `blue-green-upgrade` | Blue/green EKS migration with Route53 weighted DNS |

### Workloads: games, stateful, cost, ML

| Pattern folder | What it teaches |
|----------------|-----------------|
| `agones-game-controller` | Agones for game servers on EKS |
| `stateful` | Stateful workload considerations on EKS |
| `kubecost` | Kubecost + AWS billing integration |
| `nvidia-gpu-efa` | NVIDIA GPU + Elastic Fabric Adapter |
| `aws-neuron-efa` | AWS Neuron accelerators + EFA |
| `multi-node-vllm` | Multi-node LLM inference with vLLM |
| `ml-container-cache` | Cache large ML images for faster cold start |

---

## 11. GitOps Bridge (important mental model)

Problem: many addons need **AWS resources** (IAM roles, ACM, Route53) created by Terraform, but installing Helm from Terraform has ordering and security downsides.

**GitOps Bridge** pattern:

```
Terraform creates:
  VPC, EKS, IAM roles for addons, maybe ACM/DNS pieces
  → writes metadata into an Argo CD cluster Secret (annotations)

Argo CD (inside cluster) pulls:
  ApplicationSets from eks-blueprints-add-ons (or your fork)
  → reads metadata (role ARNs, account id, cluster name)
  → installs Helm charts with correct values
```

Why it matters:

- Cloud IAM stays in Terraform (good fit)
- Chart install becomes **pull-based** (better security for private clusters)
- Platform team controls migration/weights (see blue-green pattern) without rewriting app CD pipelines

---

## 12. Blue/green upgrade pattern (lifecycle deep dive)

High-level pieces:

| Stack | Creates |
|-------|---------|
| `environment` | Shared VPC, Route53 subdomain, ACM wildcard, Argo UI secret |
| `eks-blue` | First EKS + Argo + workloads |
| `eks-green` | Second EKS + same GitOps apps |
| Shared DNS | ExternalDNS on both → **weighted** Route53 records |

Migration idea:

```
weight blue=100 green=0  →  shift green up  →  blue=0 green=100  →  decommission blue
```

Platform team can move traffic without asking every app team to cut over manually.

---

## 13. Fully private cluster checklist

If the cluster has **no internet egress / no public API**, you typically need VPC endpoints such as:

| Endpoint | Used for |
|----------|----------|
| `ecr.api` / `ecr.dkr` | Pull images |
| `ec2` | Node/ENI operations |
| `sts` | IRSA / Fargate credentials |
| `logs` | CloudWatch Logs |
| `elasticloadbalancing` | AWS Load Balancer Controller |
| `autoscaling` | Cluster Autoscaler (if used) |
| `s3` | Often required by ECR layers and other flows |
| `ssm` | Session Manager / secrets patterns |
| `aps-workspaces` | Amazon Managed Prometheus (if used) |

Nodes still need **private endpoint access** so the kubelet can register.

---

## 14. Terraform caveats Blueprints wants you to know

| Caveat | Plain English | Practical advice |
|--------|---------------|------------------|
| VPC included in every pattern | Real orgs usually have a shared VPC workspace | Keep for demos; in prod, pass an existing VPC |
| One workspace for cluster + addons | Violates HashiCorp “no computed provider config” ideal | Use targeted apply; later split workspaces |
| Not a module | No rich variables/outputs | Fork/copy and edit `locals` |
| Static token vs `exec()` | Token lasts ~15 minutes; `exec` needs awscli | Prefer `exec` for longer applies; refresh if 401 |

### Provider auth (two options)

| Method | Pros | Cons |
|--------|------|------|
| Static `aws_eks_cluster_auth` token | Simple | Expires (~15 min) → `401` mid-apply |
| `exec { aws eks get-token }` | Fresh token each call | Needs awscli + matching client auth API version |

---

## 15. FAQ troubleshooting map

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| `terraform destroy` hangs on VPC | ENIs left by VPC CNI | Delete pods → wait → remove CNI → nodes → cluster |
| Recreate fails on CloudWatch log group | EKS recreated log group after TF deleted it | Delete log group manually, or let EKS own creation |
| Helm/K8s provider `401` | Static token expired | `terraform refresh` or switch to `exec` |
| Namespace stuck `Terminating` | Finalizers / orphan CRD objects | List resources in ns; patch finalizers if safe |
| Karpenter nodes remain after destroy | Not in Terraform state | Delete workloads/NodePools first |
| Cannot kubectl to private cluster | No path to private API | Use bastion/SSM/PrivateLink pattern |

---

## 16. How a production team should adopt Blueprints (recommended path)

Do **not** run the GitHub pattern folder forever in prod.

Suggested journey:

```
1. Pick 1–2 patterns closest to your need (e.g. karpenter-mng + external-secrets)
2. Deploy in a sandbox account; break it on purpose; practice destroy
3. Extract ideas into YOUR modules:
     network/  → existing VPC standards
     cluster/  → terraform-aws-eks wrapper
     addons/   → blueprints-addons or Argo ApplicationSets
     teams/    → blueprints-teams
4. Split state: VPC | cluster | GitOps bootstrap | app workloads
5. Add remote state (S3 + lock), CI plan on PR, OIDC for GitHub Actions
6. Define SLOs, ingress, backup, and upgrade strategy (blue-green pattern helps)
```

| Stage | Good outcome |
|-------|--------------|
| Week 1 | Sandbox cluster from a pattern; team can kubectl |
| Week 2–3 | Own module layout; IRSA for critical controllers |
| Week 4+ | GitOps for addons/apps; CI plan; private networking hardening |

---

## 17. Interview-ready one-liners

| Question | Strong answer |
|----------|---------------|
| What is EKS Blueprints? | A pattern library for complete EKS architectures in Terraform, not a cluster module |
| How do you consume it? | Reference or copy-paste; customize locals; do not `module.source` the patterns |
| What changed in v5? | Cluster/addons/teams extracted; this repo is examples only |
| Why targeted apply? | Cluster endpoint must exist before Helm providers can install charts in the same root module |
| Terraform vs GitOps for addons? | TF for cloud IAM/network; GitOps pull for charts—especially private clusters |
| Karpenter + Fargate pattern? | Run Karpenter controller on Fargate; let it create EC2 for workloads |

---

## Data flow map

```
Developer laptop
  │
  │ terraform init / targeted apply
  ▼
AWS account
  │
  ├─► VPC module
  │     public subnets (ELB tags)
  │     private subnets (internal-ELB + karpenter discovery tags)
  │     NAT (+ optional VPC endpoints for private patterns)
  │
  ├─► EKS module (terraform-aws-eks)
  │     control plane
  │     OIDC provider (IRSA / Pod Identity)
  │     Fargate profile and/or MNG and/or Auto Mode
  │     cluster addons: vpc-cni, kube-proxy, (coredns), pod-identity-agent
  │
  ├─► AWS side for controllers
  │     IAM roles, SQS (Karpenter), policies for ALB/ExternalDNS/...
  │
  └─► In-cluster install path (one of)
        A) Terraform helm_release / blueprints-addons  (push)
        B) Argo CD + GitOps Bridge metadata secret     (pull)
              │
              ▼
        Controllers running (Karpenter, LBC, External Secrets, ...)
              │
              ▼
        Workloads schedule → nodes scale → ingress/DNS/secrets wire up
```

GitOps Bridge detail:

```
Terraform (IAM role ARNs, cluster name, repo URLs)
    → Kubernetes Secret (Argo cluster annotations)
        → ApplicationSet templates
            → Helm installs with correct IRSA role per addon
```

Blue/green traffic:

```
User → Route53 weighted record
          ├─ weight N → ALB on blue cluster → app pods
          └─ weight M → ALB on green cluster → app pods
```

---

## Related files

| File | Purpose |
|------|---------|
| [1.sh](1.sh) | Deploy, kubeconfig, validate, and destroy one-liners |
| Repo `README.md` | Official consumption model and related projects |
| `docs/getting-started.md` | Canonical apply/destroy order |
| `docs/faq.md` | Token auth, ENI leaks, log groups, stuck namespaces |
| `docs/v4-to-v5/motivation.md` | Why the project was restructured |
| `patterns/karpenter/` | Best first pattern to study end-to-end |
| `patterns/gitops/getting-started-argocd/` | GitOps Bridge starter |
| `patterns/blue-green-upgrade/` | Multi-cluster migration with weighted DNS |

## Commands

All commands are one-liners in [1.sh](1.sh). Review them before running; do not apply in a shared account without checking region, name, and cost.
