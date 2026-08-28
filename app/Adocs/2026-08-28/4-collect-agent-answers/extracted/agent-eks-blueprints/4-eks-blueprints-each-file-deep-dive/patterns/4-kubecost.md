# Kubecost Pattern Files

```
reading this pattern's files
  start with README.md → intent + validate/destroy
  then providers/versions/main → locals
  then vpc / eks → infra
  then addons/helm/bootstrap → software
  then yaml/charts → runtime demos
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Scope | File-by-file deep dive for **Kubecost Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Deploy guide for Kubecost with AWS CUR/Athena billing integration.
- **What it contains:** Kubecost token prerequisite; staged apply; 24h CUR CFN follow-up; UI URL; destroy order.
- **Why it matters:** Documents two-phase flow: main stack → wait for `crawler-cfn.yml` → `run-me-in-24h/`.
- **Notable settings:** Targets `vpc` → `eks` → full; CUR CFN under `run-me-in-24h/`.

### versions.tf
- **What it is:** Terraform/provider version constraints.
- **What it contains:** TF `>= 1.3`; aws `>= 5.34,<6`; helm `>= 2.9,<3`; commented S3 backend.
- **Why it matters:** Pins providers for the Kubecost stack.
- **Notable settings:** Backend key comment `e2e/kubecost/terraform.tfstate`.

### variables.tf
- **What it is:** Input for Kubecost install token.
- **What it contains:** Required `kubecost_token` string.
- **Why it matters:** Injected into Helm values via `templatefile`.
- **Notable settings:** Token from kubecost.com install instructions.

### outputs.tf
- **What it is:** kubectl helper + CUR outputs for the 24h stack.
- **What it contains:** `configure_kubectl`, `cur_bucket_id`, `s3_cur_report_prefix`, `region`.
- **Why it matters:** Remote state consumed by `run-me-in-24h/`.
- **Notable settings:** CUR prefix from `aws_cur_report_definition`.

### main.tf
- **What it is:** Full stack: VPC, EKS, CUR/S3/Athena IAM, Kubecost Helm.
- **What it contains:** EKS ~> 20.11 (1.30); spot MNG; metrics-server; EBS CSI IRSA; CUR bucket/report; Athena results; Kubecost IRSA; cost-analyzer chart; VPC.
- **Why it matters:** Wires AWS billing into Kubecost.
- **Notable settings:** Spot MNG desired 5; chart `cost-analyzer` 1.108.1 ns `kubecost`; CUR Parquet + ATHENA artifact.

### kubecost-values.yaml
- **What it is:** Helm values template for cost-analyzer.
- **What it contains:** Token, Grafana off, IRSA annotation, LB :9090, Athena/project/spot labels.
- **Why it matters:** Links Kubecost to CUR Athena DB/table.
- **Notable settings:** Spot label `eks.amazonaws.com/capacityType=SPOT`; Athena DB `athenacurcfn_kubecost`.

### .gitignore
- **What it is:** Ignores downloaded CFN template.
- **What it contains:** `crawler-cfn.yml`.
- **Why it matters:** Avoids committing CUR-generated CFN.

### run-me-in-24h/main.tf
- **What it is:** Second-phase stack applying CUR Athena crawler CFN.
- **What it contains:** Remote state from parent; null_resource S3 download; time_sleep 60s; conditional CloudFormation stack.
- **Why it matters:** CUR needs ~24h before `crawler-cfn.yml` exists.
- **Notable settings:** Stack name `kubecost`; CAPABILITY_IAM; count only if file exists.

## Data flow map

```
README → versions/main → vpc → eks → addons/helm/gitops → yaml demos → outputs
```

## Related files

| File | Role |
|------|------|
| Index | `../4-eks-blueprints-each-file-deep-dive.md` |
| Commands | `../4.sh` |

## Commands

See [4.sh](../4.sh).
