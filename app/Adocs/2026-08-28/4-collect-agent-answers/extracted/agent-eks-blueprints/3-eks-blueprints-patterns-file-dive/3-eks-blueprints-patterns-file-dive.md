# EKS Blueprints Patterns File Dive

```
need pattern details
  → pick pattern folder under patterns/
  → read every non-image file
  → map providers → VPC/EKS → addons/workloads
  → note notable HCL/YAML keys + how files connect
```

| Question | Answer |
|---|---|
| Scope | 20 small pattern folders in terraform-aws-eks-blueprints |
| Source path | `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/` |
| Artifact type | File-by-file deep dive from actual contents |

## Summary

This document inventories every non-image file across 20 EKS Blueprints pattern folders. Each pattern section lists what each file is, what it contains, how it connects, and notable settings.

## Main Content

## aws-neuron-efa

### main.tf
- **What it is:** Terraform bootstrap for providers, locals, VPC, and kubectl helper output.
- **What it contains:** `aws` + `aws.ecr` (us-east-1) + `helm` providers; AZ data; VPC module `~> 5.0`; `configure_kubectl` output.
- **Why it matters:** Foundation for Neuron/EFA cluster; ECR alias needed for Public ECR Helm charts in `helm.tf`.
- **Notable settings:**
  - `region = "us-east-2"`
  - `vpc_cidr = "10.0.0.0/16"`, 3 AZs, single NAT
  - Helm auth via `aws eks get-token`

### eks.tf
- **What it is:** EKS cluster and managed node groups for Trainium + EFA.
- **What it contains:** `terraform-aws-modules/eks/aws` `~> 20.34`; addons; `neuron-efa` + `default` MNGs.
- **Why it matters:** Core of the pattern — Trainium nodes with EFA, placement, RAID0, taints/labels.
- **Notable settings:**
  - `cluster_version = "1.32"`, `enable_efa_support = true`
  - `ami_type = "AL2023_x86_64_NEURON"`, `trn1.32xlarge`, size 2/2/2
  - Labels `vpc.amazonaws.com/efa.present`, `aws.amazon.com/neuron.present`
  - Taint `aws.amazon.com/neuron=true:NoSchedule`
  - NodeConfig `localStorage.strategy: RAID0`

### helm.tf
- **What it is:** Device plugin Helm releases for Neuron and EFA.
- **What it contains:** Public ECR token data; `neuron-helm-chart` 1.1.1; `aws-efa-k8s-device-plugin` v0.5.7.
- **Why it matters:** Exposes Neuron devices and EFA NICs to pods that request them.
- **Notable settings:**
  - Neuron: `nodeSelector.aws.amazon.com/neuron.present`, `npd.enabled: false`
  - EFA: `nodeSelector.vpc.amazonaws.com/efa.present` + neuron toleration

### README.md
- **What it is:** Pattern docs (deploy/validate/destroy).
- **What it contains:** Architecture narrative; embed refs to `eks.tf`/`helm.tf`; kubectl validation sample.
- **Why it matters:** Explains why default MNG exists and why EFA is not separately tainted.
- **Notable settings:** Docs highlight EFA x8, placement group, RAID0, dual device plugins.

---

## ml-capacity-block

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for capacity-block GPU pattern.
- **What it contains:** `aws` + `helm`; VPC `~> 5.0`; region `us-west-2`.
- **Why it matters:** Shared infra for CBR-backed GPU MNG in `eks.tf`.
- **Notable settings:** `region = "us-west-2"`, single NAT, private subnets for EKS.

### eks.tf
- **What it is:** EKS + MNG wired to an ML Capacity Block Reservation.
- **What it contains:** Required `capacity_reservation_id` variable; EKS `~> 20.34`; `cbr` + `default` MNGs.
- **Why it matters:** Shows exact CBR knobs: AZ-pinned subnet, `CAPACITY_BLOCK`, market options, reservation target.
- **Notable settings:**
  - `ami_type = "AL2023_x86_64_NVIDIA"`, `p5e.48xlarge`
  - `capacity_type = "CAPACITY_BLOCK"`
  - `instance_market_options.market_type = "capacity-block"`
  - `capacity_reservation_id = var.capacity_reservation_id`
  - `subnet_ids = [element(private_subnets, 0)]` (AZ match TODO)
  - GPU taint + EFA/GPU labels + RAID0 + `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia-device-plugin 0.17.1; aws-efa-k8s-device-plugin v0.5.7 with GPU toleration.
- **Why it matters:** Completes GPU/EFA scheduling stack on CBR nodes.
- **Notable settings:** EFA `nodeSelector` + `nvidia.com/gpu` toleration.

### README.md
- **What it is:** CBR usage docs with three required components.
- **What it contains:** AZ restriction, LT reservation args, `capacity_type = CAPACITY_BLOCK`.
- **Why it matters:** Explains common AZ mismatch failures.
- **Notable settings:** Links to EKS/EC2 capacity blocks docs.

---

## wireguard-with-cilium

### main.tf
- **What it is:** Providers + VPC only (cluster lives in `eks.tf`).
- **What it contains:** `aws` + `helm`; VPC `~> 5.0`; `us-west-2`.
- **Why it matters:** Network base for Cilium WireGuard encryption.
- **Notable settings:** Standard public/private + single NAT.

### eks.tf
- **What it is:** EKS cluster, UDP 51871 SG rule, and Cilium Helm via blueprints-addons.
- **What it contains:** EKS `~> 20.11` (1.30); MNG `m5.large`; `eks_blueprints_addons` with Cilium 1.14.1; kubectl output.
- **Why it matters:** Entire Cilium + WireGuard config lives here.
- **Notable settings:**
  - `node_security_group_additional_rules.ingress_cilium_wireguard` UDP 51871 self
  - Cilium: `cni.chainingMode: aws-cni`, `enableIPv4Masquerade: false`, `tunnel: disabled`
  - `endpointRoutes.enabled: true`, `l7Proxy: false`
  - `encryption.enabled: true`, `encryption.type: wireguard`

### example.yaml
- **What it is:** Optional client/server pods to demo encrypted traffic.
- **What it contains:** nginx `server` pod+Service; busybox `client` with `watch wget`; topology spread.
- **Why it matters:** Used with tcpdump on `cilium_wg0` in README validate steps.
- **Notable settings:** Labels `blog: wireguard`; Service `sessionAffinity: ClientIP`.

### README.md
- **What it is:** Deploy/validate guide for WireGuard encryption.
- **What it contains:** Focal points; `cilium status` Encryption field; tcpdump + connectivity-check steps.
- **Why it matters:** Shows expected `Encryption: Wireguard` and NodeEncryption Disabled.
- **Notable settings:** Requires Linux kernel 5.10+.

---

## external-secrets

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

## fargate-serverless

### versions.tf
- **What it is:** Provider constraints for Fargate pattern.
- **What it contains:** aws, helm, kubernetes `>= 2.20`.
- **Why it matters:** Kubernetes provider used for sample app.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Fargate-only EKS + addons + 2048 sample app.
- **What it contains:** EKS Fargate profiles; blueprints-addons (CoreDNS Fargate sizing, Fluent Bit, ALB controller); VPC; Deployment/Service for `app-2048`.
- **Why it matters:** Shows serverless data plane patterns and Fargate-specific CoreDNS/logging.
- **Notable settings:**
  - Profiles: `app-*` and `kube-system`
  - `create_cluster_security_group/create_node_security_group = false`
  - CoreDNS `computeType = Fargate`, cpu/memory `0.25` / `256M`
  - `enable_fargate_fluentbit = true`, `flb_log_cw = true`
  - ALB controller with `vpcId` set
  - App toleration `eks.amazonaws.com/compute-type=fargate`

### outputs.tf
- **What it is:** kubectl helper output.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Cluster access after apply.
- **Notable settings:** Region-scoped update-kubeconfig.

### README.md
- **What it is:** Validate Fargate nodes, Fluent Bit CW logs, ALB ingress example.
- **What it contains:** Sample outputs; ingress create annotations; destroy partial.
- **Why it matters:** Operational checklist for serverless cluster.
- **Notable settings:** Ingress class `alb`, scheme internet-facing, target-type ip.

---

## fully-private-cluster

### versions.tf
- **What it is:** Minimal provider set (AWS only).
- **What it contains:** aws `>= 5.34, < 6.0`.
- **Why it matters:** No Helm/K8s providers — infra-only private cluster.
- **Notable settings:** Commented e2e backend.

### main.tf
- **What it is:** Private VPC (no NAT/public) + VPC endpoints + private EKS.
- **What it contains:** EKS `~> 20.11` with private subnets only; VPC without public subnets/`enable_nat_gateway = false`; Interface+Gateway endpoints.
- **Why it matters:** Demonstrates air-gapped-style cluster dependency on VPC endpoints.
- **Notable settings:**
  - No `cluster_endpoint_public_access = true` (module default private)
  - Endpoints: s3 gateway + autoscaling, ecr.api/dkr, ec2, ec2messages, elb, sts, kms, logs, ssm, ssmmessages
  - Endpoint SG allows HTTPS from VPC CIDR

### outputs.tf
- **What it is:** kubectl config tip (assumes reachable private API).
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Access requires network path into VPC (VPN/Direct Connect/bastion).
- **Notable settings:** Same update-kubeconfig pattern as other patterns.

### README.md
- **What it is:** Private cluster requirements and endpoint list.
- **What it contains:** Required VPC endpoints list; validate nodes/pods; destroy.
- **Why it matters:** Documents why endpoints exist and extra ones (APS, etc.).
- **Notable settings:** Mentions private endpoint access for node registration.

---

## ipv6-eks-cluster

### versions.tf
- **What it is:** AWS provider pin for IPv6 pattern (module v21 era).
- **What it contains:** aws `>= 6.0`.
- **Why it matters:** Matches VPC/EKS module major upgrades used below.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Dual-stack VPC + IPv6 EKS cluster.
- **What it contains:** EKS module `~> 21.0.7` with `ip_family = "ipv6"`; VPC `~> 6.0.1` with IPv6 prefixes and egress-only IGW.
- **Why it matters:** Shows IPv6 cluster + subnet IPv6 assignment knobs.
- **Notable settings:**
  - `ip_family = "ipv6"`, `create_cni_ipv6_iam_policy = true`
  - `kubernetes_version = "1.33"`, `endpoint_public_access = true`
  - `enable_ipv6`, `create_egress_only_igw = true`
  - Public prefixes `[0,1,2]`, private `[3,4,5]`, `private_subnet_enable_dns64 = false`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl` referencing `module.eks.cluster_name`.
- **Why it matters:** Post-deploy access.
- **Notable settings:** Region `us-west-2`.

### README.md
- **What it is:** Validate pods/nodes show IPv6 addresses.
- **What it contains:** `kubectl get pods/nodes -o wide` sample IPv6 INTERNAL-IP.
- **Why it matters:** Success criteria for the pattern.
- **Notable settings:** Expect pod IPs like `2600:1f13:...`.

---

## istio

### versions.tf
- **What it is:** Provider constraints for Istio pattern.
- **What it contains:** aws, helm, kubernetes.
- **Why it matters:** Helm installs Istio charts; kubernetes creates namespace.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** EKS + Istio base/istiod/gateway Helm + ALB controller + SG rules.
- **What it contains:** EKS with ports 15017/15012; `istio-system` ns; blueprints-addons Helm releases for base/istiod/gateway; VPC.
- **Why it matters:** Full mesh control plane + internet-facing NLB ingress gateway.
- **Notable settings:**
  - Istio charts `1.20.2` from `istio-release.storage.googleapis.com`
  - `meshConfig.accessLogFile = /dev/stdout`
  - Gateway annotations: NLB external, target-type ip, internet-facing, cross-zone
  - Label `istio = ingressgateway`
  - `enable_aws_load_balancer_controller = true`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Access for validate/rollout restart.
- **Notable settings:** Standard update-kubeconfig.

### README.md
- **What it is:** Deploy, observability addons, helloworld validate, destroy caveats.
- **What it contains:** `kubectl rollout restart` for istiod dependency; Kiali/Jaeger/Prometheus/Grafana; sample apps; destroy targeting istio-ingress first.
- **Why it matters:** Documents known Istio/ALB destroy race and ingress restart need.
- **Notable settings:** Observability from Istio release-1.20 samples.

---

## multi-tenancy-with-teams

### versions.tf
- **What it is:** Provider pin (aws + kubernetes).
- **What it contains:** No helm.
- **Why it matters:** Teams module uses kubernetes resources.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** EKS with aws-auth managed by teams modules (admin + red/blue).
- **What it contains:** EKS `~> 19.21`; `eks-blueprints-teams` admin + for_each red/blue; VPC; kubernetes provider via `aws_eks_cluster_auth` token.
- **Why it matters:** Namespace isolation with quotas/limit ranges and IAM/aws-auth roles per team.
- **Notable settings:**
  - `manage_aws_auth_configmap = true`
  - Admin: `enable_admin = true`, users = caller ARN
  - Dev teams: namespaces `team-red`/`team-blue` with CPU/mem/pod quotas and LimitRanges
  - Cluster version `1.29`

### outputs.tf
- **What it is:** Per-team kubeconfig role ARN helpers.
- **What it contains:** Admin + list of dev team `update-kubeconfig --role-arn` commands.
- **Why it matters:** Shows how each tenant assumes its IAM role.
- **Notable settings:** Role ARNs from teams modules.

### README.md
- **What it is:** High-level tenancy description (TODO validate).
- **What it contains:** team-red/blue + admin overview.
- **Why it matters:** Intent statement for the pattern.
- **Notable settings:** Validation section marked TODO.

---

## private-public-ingress

### versions.tf
- **What it is:** aws + helm constraints.
- **What it contains:** No kubernetes provider (ingress via Helm addons only).
- **Why it matters:** Two ingress-nginx Helm installs.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Bottlerocket EKS + dual ingress-nginx (external/internal) + ALB controller.
- **What it contains:** Two SGs; two `eks_blueprints_addons` modules for nginx; third for ALB controller 1.6.0; VPC.
- **Why it matters:** Split public vs private ingress classes with dedicated NLBs/SGs.
- **Notable settings:**
  - AMI `BOTTLEROCKET_x86_64`, 3 nodes
  - External: scheme `internet-facing`, SG open 80/443 to `0.0.0.0/0`
  - Internal: scheme `internal`, SG limited to VPC CIDR
  - Classes `ingress-nginx-external` / `ingress-nginx-internal`
  - `loadBalancerClass: service.k8s.aws/nlb`, topology spread, minAvailable 2

### outputs.tf
- **What it is:** kubectl helper with alias.
- **What it contains:** `update-kubeconfig --alias`.
- **Why it matters:** Convenience naming for multi-cluster local configs.
- **Notable settings:** Alias = cluster name.

### README.md
- **What it is:** Explains dual controllers + ingressClassName usage.
- **What it contains:** Deploy; TODO validate; destroy.
- **Why it matters:** How apps choose public vs private ingress.
- **Notable settings:** Set `ingressClassName` to external or internal class.

---

## stateful

### versions.tf
- **What it is:** aws/helm/kubernetes providers.
- **What it contains:** Needed for storage classes + addons.
- **Why it matters:** Stateful storage CRDs managed by kubernetes provider.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Stateful-focused EKS: multi-volume + instance-store MNGs, Velero, EFS/EBS CSI, storage classes, KMS.
- **What it contains:** Two MNGs with custom block devices/user data; blueprints-addons; gp2 annotate / gp3+efs StorageClasses; S3 backup bucket; EFS; EBS KMS; EBS CSI IRSA.
- **Why it matters:** Reference for PV/storage best practices and node disk layout.
- **Notable settings:**
  - `multi-volume`: `/dev/xvdb` 24Gi gp3 encrypted; shell mounts containerd dirs
  - `instance-store`: `m5ad.large` + NodeConfig RAID0
  - Velero `s3_backup_location`; `enable_aws_efs_csi_driver`
  - gp3 default SC; efs SC `provisioningMode=efs-ap`
  - SSM policy on nodes for validation

### outputs.tf
- **What it is:** kubectl + Velero location outputs.
- **What it contains:** `configure_kubectl`, `velero_s3_backup_location`.
- **Why it matters:** Points operators at backup bucket path.
- **Notable settings:** Location = bucket ARN + `/backups`.

### README.md
- **What it is:** Feature guide for Velero, CSI, multi-volume, instance store.
- **What it contains:** Validate SC list, nvme-cli checks, velero CLI location.
- **Why it matters:** How to verify containerd on second volume and NVMe mounts.
- **Notable settings:** Expect `gp3 (default)`, `efs`, `gp2` present.

---

## tls-with-aws-pca-issuer

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

## sso-okta

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

## targeted-odcr

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for ODCR pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for ODCR GPU MNG in `eks.tf`.
- **Notable settings:** Standard 3-AZ VPC.

### eks.tf
- **What it is:** EKS MNG targeting a Capacity Reservation resource group + ODCR resource group resources.
- **What it contains:** `capacity_reservation_arns` var; EKS; `odcr` + `default` MNGs; `aws_resourcegroups_group` CapacityReservationPool; group memberships.
- **Why it matters:** Shows targeted ODCR via resource group ARN (add/remove capacity without LT rewrite).
- **Notable settings:**
  - `p5.48xlarge`, NVIDIA AMI, EFA, RAID0, GPU taint
  - `capacity_reservation_resource_group_arn = aws_resourcegroups_group.odcr.arn`
  - AZ-pinned first private subnet
  - Duplicate min/max/desired blocks (2/2/2 then 4/5/2 — last wins in HCL)

### helm.tf
- **What it is:** NVIDIA + EFA device plugins (same pattern as CBR/GPU).
- **What it contains:** nvidia 0.17.1; efa v0.5.7 with GPU toleration.
- **Why it matters:** Device exposure for ODCR GPU nodes.
- **Notable settings:** EFA nodeSelector + nvidia toleration.

### README.md
- **What it is:** Three-component ODCR recipe + console validation (images skipped).
- **What it contains:** AZ pin, LT reservation spec, resource group container model.
- **Why it matters:** Explains why resource groups allow capacity changes without node group disruption.
- **Notable settings:** Links to EC2 ODCR tutorials.

---

## ecr-pull-through-cache

### main.tf
- **What it is:** TF/providers/locals for pull-through cache pattern.
- **What it contains:** TF `>= 1.8`; aws/helm/kubernetes; account/AZ data; `cluster_version = "1.30"`.
- **Why it matters:** Shared locals (`name`, `region`, `ecr_url` used in addons).
- **Notable settings:** Region `us-west-2`.

### variables.tf
- **What it is:** Docker Hub credentials for authenticated pull-through.
- **What it contains:** Sensitive object `{username, accessToken}`.
- **Why it matters:** Required for docker-hub cache rule.
- **Notable settings:** Sensitive = true.

### vpc.tf
- **What it is:** Standard VPC module.
- **What it contains:** VPC `~> 5.9`, public/private, single NAT, ELB tags.
- **Why it matters:** Network for EKS nodes pulling via ECR.
- **Notable settings:** Private subnets for cluster.

### eks.tf
- **What it is:** EKS MNG with ECR pull-through IAM + EBS CSI IRSA + kubectl output.
- **What it contains:** EKS `~> 20.20`; IAM policy `ECRPullThroughCache`; node policies include that policy; ebs_csi_driver_irsa.
- **Why it matters:** Nodes can CreateRepository/BatchImportUpstreamImage for cache.
- **Notable settings:**
  - Policy actions: CreateRepository, BatchImportUpstreamImage, TagResource
  - Also `AmazonEC2ContainerRegistryReadOnly`
  - Addons: ebs-csi, coredns, kube-proxy, vpc-cni before_compute

### ecr.tf
- **What it is:** Secrets Manager docker secret + ECR registry pull-through rules + enhanced scanning.
- **What it contains:** secrets-manager module; ecr module with 4 rules (ecr/k8s/quay/dockerhub).
- **Why it matters:** Defines prefixes and upstream registries used by Helm image rewrites.
- **Notable settings:**
  - Prefixes: `ecr`, `k8s`, `quay`, `docker-hub`
  - dockerhub `credential_arn` from secret
  - `registry_scan_type = ENHANCED`, SCAN_ON_PUSH `*`

### addons.tf
- **What it is:** Blueprints addons + Gatekeeper with images rewritten to ECR cache URLs.
- **What it contains:** Argo CD, metrics-server, ALB controller, kube-prometheus-stack; separate gatekeeper addon module.
- **Why it matters:** Proves pull-through by forcing all chart images through account ECR prefixes.
- **Notable settings:**
  - `local.ecr_url = ACCOUNT.dkr.ecr.REGION.amazonaws.com`
  - Image repos under `/quay/...`, `/docker-hub/...`, `/k8s/...`, `/ecr/...`

### README.md
- **What it is:** Deploy with docker_secret var; validate cache rules; destroy ECR repos first.
- **What it contains:** `validate-pull-through-cache-rule` loop; pod list; mass ECR delete note.
- **Why it matters:** Cleanup guidance for auto-created cache repos.
- **Notable settings:** Apply var example for docker secret.

---

## karpenter

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

## karpenter-mng

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

## multi-node-vllm

### main.tf
- **What it is:** Providers/locals/VPC for multi-node vLLM + LWS.
- **What it contains:** aws/helm/http/kubectl/local providers; region `us-east-2`; VPC.
- **Why it matters:** http+kubectl pull LWS manifests; local writes `build.sh`.
- **Notable settings:** TF providers include `hashicorp/http` and `alekc/kubectl`.

### eks.tf
- **What it is:** EKS with `g6e.8xlarge` EFA GPU MNG + default MNG.
- **What it contains:** EKS `~> 20.34`; EFA support; RAID0; GPU taint/labels; subnet pinned to 3rd private subnet.
- **Why it matters:** Hardware base for pipeline-parallel vLLM across nodes.
- **Notable settings:**
  - `ami_type = AL2023_x86_64_NVIDIA`, `g6e.8xlarge`
  - `subnet_ids = [element(private_subnets, 2)]`
  - Cluster `1.32`

### helm.tf
- **What it is:** Device plugins + LeaderWorkerSet install from GitHub release manifests.
- **What it contains:** nvidia/efa helm; `data.http` LWS v0.5.1 manifests applied via kubectl_manifest for_each.
- **Why it matters:** LWS CRD/controller required by `lws.yaml`.
- **Notable settings:** `lws_version = "v0.5.1"`, server_side_apply true.

### ecr.tf
- **What it is:** ECR repo + generated `build.sh` for image build/push and lws.yaml image sed.
- **What it contains:** ecr module; `local_file.vllm` bash script with zstd OCI build.
- **Why it matters:** Bridges Dockerfile → private ECR → LeaderWorkerSet image field.
- **Notable settings:** `repository_force_delete = true`; sed updates `./lws.yaml` image.

### lws.yaml
- **What it is:** vLLM LeaderWorkerSet + ClusterIP Service.
- **What it contains:** LWS size 4; leader OpenAI API server; workers ray_init; EFA/NCCL env; GPU+EFA resource requests.
- **Why it matters:** Workload definition for Llama-3.3-70B pipeline parallel.
- **Notable settings:**
  - `--pipeline-parallel-size 4`, `--tensor-parallel-size 1`
  - `FI_PROVIDER=efa`, HF token placeholder
  - Requests `nvidia.com/gpu: 1`, `vpc.amazonaws.com/efa: 1`, ephemeral-storage 160Gi

### Dockerfile
- **What it is:** Ubuntu 22.04 image with vLLM + EFA + NCCL + aws-ofi-nccl.
- **What it contains:** CUDA keyring; pip vllm; EFA installer 1.37.0; NCCL 2.25.1; aws-ofi-nccl 1.13.2-aws; ray_init.sh.
- **Why it matters:** Collective comms stack for multi-node GPU inference over EFA.
- **Notable settings:** CUDA 12.4; removes bundled NCCL; sm_89 gencode; hf_transfer.

### README.md
- **What it is:** End-to-end deploy/build/infer validate; quota warning for G/VT vCPUs.
- **What it contains:** build.sh timing note; HF token step; curl completion sample.
- **Why it matters:** Operational path after Terraform.
- **Notable settings:** Needs ≥64 vCPU G/VT quota for two g6e.8xlarge.

---

## nvidia-gpu-efa

### main.tf
- **What it is:** Providers/VPC/output for NVIDIA+EFA pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for p5 GPU cluster.
- **Notable settings:** Standard VPC layout.

### eks.tf
- **What it is:** EKS with `p5.48xlarge` NVIDIA EFA MNG + default MNG.
- **What it contains:** Same shape as other GPU patterns: RAID0, EFA, labels, GPU taint.
- **Why it matters:** Hardware for NCCL/EFA MPIJob tests.
- **Notable settings:**
  - `AL2023_x86_64_NVIDIA`, `p5.48xlarge`, size 2
  - Cluster `1.32`, `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia 0.17.1; efa v0.5.7.
- **Why it matters:** Required before MPIJobs can request GPU/EFA resources.
- **Notable settings:** EFA tolerates `nvidia.com/gpu`.

### generate-efa-info-test.sh
- **What it is:** Bash generator for Kubeflow MPIJob that runs `fi_info -p efa`.
- **What it contains:** Env defaults (2 workers, 8 GPU, 32 EFA); writes `efa-info-test.yaml`.
- **Why it matters:** Validate EFA devices visible inside pods.
- **Notable settings:** Image `public.ecr.aws/hpc-cloud/nccl-tests:latest`; MPIJob v2beta1.

### generate-efa-nccl-test.sh
- **What it is:** Bash generator for NCCL all_reduce_perf MPIJob.
- **What it contains:** FI_/NCCL_ env; hugepages/memory requests; writes `efa-nccl-test.yaml`.
- **Why it matters:** Measure multi-node EFA bandwidth.
- **Notable settings:**
  - `INSTANCE_TYPE=p5e.48xlarge` (differs from eks.tf `p5.48xlarge`)
  - `EFA_PER_WORKER=32`, `GPU_PER_WORKER=8`
  - HostPath `/dev/shm`

### .gitignore
- **What it is:** Ignore generated MPIJob manifests.
- **What it contains:** `efa-info-test.yaml`, `efa-nccl-test.yaml`.
- **Why it matters:** Generated artifacts stay local.
- **Notable settings:** Two yaml filenames only.

### README.md
- **What it is:** Full validate path: MPI operator, info test, NCCL test, sample bandwidth logs.
- **What it contains:** Deploy MPI operator YAML; script usage; destroy.
- **Why it matters:** How to prove EFA/NCCL health on the cluster.
- **Notable settings:** Mentions optional ODCR block in eks.tf (commented in narrative).

---

## sso-iam-identity-center

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

## Data Flow Map

```
pattern folder
  ├─ versions/main providers + locals
  ├─ vpc (or inline module) → private subnets (+ tags)
  ├─ eks module → cluster + MNG/Fargate + addons/access
  ├─ sidecar files (helm/ecr/sso/okta/karpenter/teams)
  └─ optional YAML/scripts → post-apply workloads / validate
```

Cross-cutting ML GPU family (`aws-neuron-efa`, `ml-capacity-block`, `targeted-odcr`, `nvidia-gpu-efa`, `multi-node-vllm`):

```
VPC → EKS (enable_efa_support)
  → GPU/Neuron MNG (AMI + RAID0 + labels/taints + optional CBR/ODCR)
  → default MNG (addons)
  → device plugin Helm
  → (optional) LWS/MPIJob/vLLM manifests
```

## Related Files

| Path | Role |
|---|---|
| `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/` | Source patterns |
| `3.sh` | Placeholder (no commands to auto-run) |

## Commands

See `3.sh` — no live CLI was run; listing-only helper for local browsing.
