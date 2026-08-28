# VPC Lattice Pattern Files

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
| Scope | File-by-file deep dive for **VPC Lattice Pattern Files** |
| How to read | Dependency order: providers → network → cluster → addons → manifests |

## Summary

Each subsection explains one file: what it is, what it contains, why it matters, and notable settings.

### README.md
- **What it is:** Index linking client-server and cross-cluster Lattice patterns.

## client-server-communication

### README.md
- **What it is:** EKS app in VPC A exposed to EC2 client in VPC B via Lattice + custom DNS.
- **Notable settings:** Auth type NONE; SSM curl `http://server.example.com`.

### main.tf / versions.tf / variables.tf / outputs.tf
- **What they are:** Locals (cluster CIDR 10.0, client 10.1); providers aws/helm/time; kubectl output.

### eks.tf
- **What it is:** Cluster VPC, EKS, Gateway API Controller + ExternalDNS, demo Helm, Lattice SG allow.
- **Notable settings:** Controller chart v1.0.3; `defaultServiceNetwork=""`.

### lattice.tf
- **What it is:** Service network + VPC associations + private Route53 zone `example.com` on client VPC.
- **Notable settings:** time_sleep 120s after demo helm.

### client.tf
- **What it is:** Client VPC (private only) + SSM EC2 + VPC endpoints for SSM (no NAT).

### charts/demo-application/*
- Deployment/Service `server`; GatewayClass `amazon-vpc-lattice`; Gateway; HTTPRoute `server.example.com`.

## cross-cluster-pod-communication

### README.md
- **What it is:** Two EKS clusters (overlapping CIDRs OK), Lattice + IAM SigV4 + private CA TLS.
- **Notable settings:** Workspaces `cluster1` / `cluster2`; Kyverno sidecar injection.

### environment/*
- Shared private zone, ACM PCA root + ACM wildcard, Pod Identity IAM role (Lattice invoke + PCA read).

### cluster/main.tf / remote_state.tf / vpc.tf / eks.tf
- Per-workspace EKS; associate private hosted zone; Gateway API Controller v1.0.5; Kyverno; platform/demo Helm; Pod Identity; Lattice SG.
- **Notable settings:** `allowedCluster` flips by workspace; both CIDR `10.0.0.0/16`.

### cluster/deploy.sh / destroy.sh
- Workspace helpers; destroy cleans Lattice VPC associations/endpoints/SGs (often twice).

### cluster/charts/platform/*
- GatewayClass/Gateway with HTTPS + IAMAuthPolicy; Kyverno policy injects iptables init + `envoy-sigv4` sidecar.

### cluster/charts/demo/*
- App Deployment/Service + HTTPRoute with IAMAuthPolicy requiring PrincipalTag cluster/namespace.

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
