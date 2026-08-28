# WireGuard Cilium Pattern Files

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
| Scope | File-by-file deep dive for **WireGuard Cilium Pattern Files** |
| How to read | Top → bottom dependency order (providers → VPC → EKS → addons → manifests) |
| Not a module | Copy/adapt locally; do not `module.source` this pattern folder |

## Summary

Each subsection below explains one file: what it is, what it contains, why it matters, and notable settings.

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
