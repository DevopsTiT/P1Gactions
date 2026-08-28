# Istio Pattern Files

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
| Scope | File-by-file deep dive for **Istio Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

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
