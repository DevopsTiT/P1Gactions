# Bottlerocket Pattern Files

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
| Scope | File-by-file deep dive for **Bottlerocket Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Bottlerocket MNG + Karpenter + BRUPOP patch automation.
- **What it contains:** Validate labels, BRUPOP pods, AMI upgrade, Karpenter inflate test.
- **Why it matters:** Shows OS patching (not minor/major k8s upgrades).
- **Notable settings:** Pinned MNG AMI to demo updates.

### versions.tf / outputs.tf / main.tf
- **What they are:** Provider pins; kubectl output; dual aws providers + k8s/helm (`aws.ecr` for public ECR).
- **Notable settings:** Name truncated to 12 chars; region `us-west-2`.

### vpc.tf
- **What it is:** VPC with Karpenter discovery tags on private subnets.

### eks.tf
- **What it is:** EKS with Bottlerocket MNG + EBS CMK.
- **What it contains:** BOTTLEROCKET_x86_64 MNG; encrypted xvda/xvdb; bootstrap TOML (admin off, lockdown, BRUPOP label, CriticalAddonsOnly taint).
- **Why it matters:** Hardened OS nodes reserved for critical addons.

### addons.tf
- **What it is:** cert-manager, Karpenter, BRUPOP, Karpenter CR Helm chart.
- **Notable settings:** BRUPOP cron very frequent for demo; CriticalAddonsOnly tolerations.

### example.yaml
- **What it is:** Pause Deployment `inflate` for Karpenter scale test (replicas 0).

### karpenter-resources/Chart.yaml / values.yaml / templates/nodepool.yaml / templates/ec2nodeclass.yaml
- **What they are:** Local Helm chart for Karpenter NodePool (v1beta1) + Bottlerocket EC2NodeClass with KMS-encrypted volumes.

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
