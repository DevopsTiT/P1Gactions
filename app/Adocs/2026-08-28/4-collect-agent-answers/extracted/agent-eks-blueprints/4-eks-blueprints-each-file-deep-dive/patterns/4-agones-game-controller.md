# Agones Game Controller Pattern Files

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
| Scope | File-by-file deep dive for **Agones Game Controller Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Agones on EKS for dedicated game servers (+ FleetIQ context).
- **What it contains:** Deploy/validate with sample GS + netcat; destroy GS first.
- **Why it matters:** Operational test path for UDP game servers.

### versions.tf / outputs.tf
- **What they are:** aws+helm pins; `configure_kubectl` output.

### main.tf
- **What it is:** VPC + EKS with Agones-specific node groups and Helm Agones.
- **What it contains:** EKS 1.30; nodes in **public** subnets; MNGs default/agones_system/agones_metrics; UDP 7000–8000 + webhook 8081 SG; Agones Helm 1.32.0; metrics-server + cluster-autoscaler.
- **Why it matters:** Public nodes + open UDP range required for client connectivity.
- **Notable settings:** `map_public_ip_on_launch = true`; ns `agones-system`.

### helm_values/agones-values.yaml
- **What it is:** Agones Helm values template (Ping/allocator NLBs; gameserver port range).
- **Why it matters:** Exposes Agones control plane publicly via NLB.

### test/sample-game-server/gameserver.yaml / fleet.yaml
- **What they are:** Simple Agones GameServer and Fleet (`simple-game-server:0.3`, port 7654).

### test/xonotic/* (gameserver, fleet, fleetautoscaler, gameserverallocator)
- **What they are:** Xonotic example showing Fleet Recreate, buffer autoscaler (2–10), allocation selector.

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
