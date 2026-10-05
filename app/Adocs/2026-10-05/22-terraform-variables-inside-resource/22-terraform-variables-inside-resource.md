# Terraform Variables Inside Resource

## Decision tree

```
Want to move variable / locals blocks into the resource block?
 inside resource "..." { variable "x" {...} }  → NOT ALLOWED → terraform validate fails ("Blocks of type variable are not expected here")
 keep them at the top of the same .tf file     → OK (Option A, what main.tf already does)
 repo keeps variables in variables.tf          → move them there; resources still use var.x / local.x
 want one self-contained block per alert       → drop variable/locals, write the values inline (Option B, inline.tf)
 other files in the same folder use the same names? → "Duplicate variable/local" error → rename (e.g. cisco_ldap_*)
```

## Short takeaway

| Question | Answer |
|---|---|
| Can `variable` go inside a `resource`? | No. `variable`, `locals`, `output` and `provider` are top-level blocks only |
| Can they stay in the same file as the resource? | Yes. Terraform reads every `.tf` file in the folder as one module; position in the file doesn't matter |
| Can I avoid them completely? | Yes. Put the values directly in the resource (Option B) |
| Watch out for | Names must be unique across all `.tf` files in the folder, and the placeholder email must be replaced |

## Summary

Terraform does not allow `variable` or `locals` blocks inside a `resource`. They must sit at the top level of a `.tf` file. Keeping them at the top of the same file as the alert is fine, and that's what `main.tf` in seq 21 does. If your team prefers every alert file to be a single resource block like the other files in `G/configuration`, write the values inline instead. Both versions create exactly the same detector and workflow.

## What is allowed where

| Block | Top level of a .tf file | Inside a resource |
|---|---|---|
| `variable "x" {}` | Yes | No |
| `locals {}` | Yes | No |
| `output "x" {}` | Yes | No |
| `resource "..." "..." {}` | Yes | No |
| `var.x` (using a variable) | Yes | Yes |
| `local.x` (using a local) | Yes | Yes |
| `"${var.x}"` inside a heredoc | Yes | Yes |

So the *definition* goes outside, and the *use* (`var.network_bucket_pattern`, `local.ldap_filter`) goes inside.

## What happens if you nest it

```hcl
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  variable "network_bucket_pattern" {   # not allowed here
    default = "network*"
  }
  ...
}
```

`terraform validate` stops with an error like: `Blocks of type "variable" are not expected here.`

## Option A: keep them at the top of the same file (current main.tf)

```hcl
variable "network_bucket_pattern" { ... }
variable "ldap_alert_email_to"    { ... }
locals { ldap_name = ...  ldap_filter = ... }

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title = local.ldap_name
  ...
  value = <<-EOT
    fetch logs
    ${local.ldap_filter}
    | makeTimeseries count = count(default: 0), interval:1m
  EOT
}
```

| Good | Watch out |
|---|---|
| The filter is written once and shared by the detector and the email query | Every `.tf` file in the folder shares one namespace. If another alert file also declares `variable "network_bucket_pattern"` or a local named `ldap_name`, you get a "Duplicate" error |
| Easy to change the bucket or recipients in one place | If your repo keeps variables in `variables.tf`, move the two `variable` blocks there to match |

## Option B: write the values inline (inline.tf)

No `variable` or `locals` blocks at all. The bucket, filter, name and recipient are typed straight into both resources:

```hcl
value = <<-EOT
  fetch logs
  | filter matchesValue(dt.system.bucket, "network*")
  | filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
  | dedup timestamp, content
  | makeTimeseries count = count(default: 0), interval:1m
EOT
```

| Good | Watch out |
|---|---|
| Matches the "one block per alert" style of the other files | The filter appears twice (detector and email query). Change both if you edit it |
| No risk of duplicate names with other files | Recipients are hard-coded; fine for a DL, but update both places if the bucket changes |

## Things to fix either way

| Item | Why |
|---|---|
| Replace `<network-team-dl>@axa.co.jp` | It's a placeholder. Take the real recipients from the Splunk "Send email" action |
| Confirm `network*` | Run the bucket check from seq 21 `check.dql` query 1 |
| Test `dedup timestamp, content` in a Notebook | If the syntax is rejected or there are no duplicates, remove the line |

## Data flow

```
variable / locals (top level of a .tf file, or none)
  → referenced as var.x / local.x inside the resource
  → terraform plan renders the final DQL text
  → Dynatrace detector + email workflow get the same values either way
```

## Investigation

| Checked | Finding |
|---|---|
| Your question | Whether the `variable` and `locals` blocks can go inside the resources |
| Terraform language rules | `variable` and `locals` are top-level blocks only; references work anywhere |
| Seq 21 `main.tf` | Already uses Option A (blocks at the top of the same file) |
| Team files in `G/configuration` | Each file is one resource block with literal values, so Option B matches their style |

## Result

Don't nest them inside the resource. Either keep them at the top of the file (Option A, seq 21 `main.tf`) or drop them and use literal values (Option B, `22-terraform-variables-inside-resource-inline.tf`). Replace the placeholder email before applying.

## Related files

| File | Purpose |
|---|---|
| `22-terraform-variables-inside-resource-inline.tf` | Option B, values written inline |
| `2026-10-05/21-cisco-vpn-ldap-two-alerts-transform/21-cisco-vpn-ldap-two-alerts-transform-main.tf` | Option A |
| `22.sh` | Validate and plan one-liners |

## Commands

See `22.sh` (not run).
