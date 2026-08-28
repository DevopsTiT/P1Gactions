# Root Files Deep Dive

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
| Scope | File-by-file deep dive for **Root Files Deep Dive** |
| Source | terraform-aws-eks-blueprints-main |

## Summary

### README.md

| Field | Detail |
|---|---|
| What it is | Project landing README for Amazon EKS Blueprints for Terraform |
| What it contains / does | Explains motivation (opinionated complete EKS clusters), consumption model (reference or copy-paste, not as a Terraform module), related projects (addon/addons/teams modules, GitOps, Data on EKS, Observability Accelerator, Karpenter Blueprints, GitLab CD component), Terraform caveats (bundled VPC, single-workspace + targeted apply, no module-style vars/outputs), support/feedback, security pointer, Apache-2.0 license |
| Why it matters | Primary onboarding and sets the non-module consumption contract |
| Notable details | Points to FAQ for kubernetes/helm/kubectl provider auth (static token vs `exec`); lists supporting modules `terraform-aws-eks-blueprint-addon(s)` and `terraform-aws-eks-blueprints-teams` |

### ADOPTERS.md

| Field | Detail |
|---|---|
| What it is | Self-reported adopters list |
| What it contains / does | Table of Organization, Description, Contacts, Link; invites PRs to add entries |
| Why it matters | Social proof and contact points for other implementers |
| Notable details | Alphabetical adopters include PITS Global Data Recovery Services, AlgoDx AB, Swyft Logistics; excluded from cspell in pre-commit |

### CODE_OF_CONDUCT.md

| Field | Detail |
|---|---|
| What it is | Code of conduct pointer |
| What it contains / does | Adopts Amazon Open Source Code of Conduct; FAQ link; `opensource-codeofconduct@amazon.com` |
| Why it matters | Community behavior baseline |
| Notable details | Thin wrapper; full text lives on aws.github.io |

### CONTRIBUTING.md

| Field | Detail |
|---|---|
| What it is | Contributing guidelines |
| What it contains / does | Bug/feature reporting tips; PR workflow (fork, focus change, tests, clear commits, watch CI); find `help wanted` issues; CoC; **security issues via AWS vulnerability page, not public GitHub issues**; licensing note |
| Why it matters | How external contributors interact safely and effectively |
| Notable details | Security path is explicit and non-negotiable for vulns |

### LICENSE

| Field | Detail |
|---|---|
| What it is | Full Apache License 2.0 text |
| What it contains / does | Standard Apache-2.0 terms (copyright/patent grants, redistribution, contribution terms, AS-IS warranty, liability) |
| Why it matters | Legal basis for use, redistribution, and contributions |
| Notable details | Matches README “Apache-2.0 Licensed” |

### NOTICE.txt

| Field | Detail |
|---|---|
| What it is | Apache NOTICE attribution file |
| What it contains / does | Copyright 2016–2022 Amazon.com, Inc. or affiliates; Apache-2.0 reference (`http://aws.amazon.com/apache2.0/`) |
| Why it matters | Required NOTICE companion under Apache-2.0 redistribution |
| Notable details | Short; copyright years end at 2022 while mkdocs copyright says 2024 |

### .gitignore

| Field | Detail |
|---|---|
| What it is | Git ignore rules |
| What it contains / does | Ignores IDE/OS junk, MkDocs `/site`, `.terraform`, lockfile, tfstate/tfplan, crash logs, `*.tfvars`, override tf files, terraformrc, `.tfsec`, `*.envrc`, `*kube-config.yaml`, `builds`, `__pycache__` |
| Why it matters | Keeps secrets, local state, and generated docs out of git |
| Notable details | Explicit comment that `.tfvars` often hold sensitive data |

### .pre-commit-config.yaml

| Field | Detail |
|---|---|
| What it is | Pre-commit hook config for local and CI quality |
| What it contains / does | Hooks: `cspell` (v9.0.1) with many path excludes; `pretty-format-yaml`; trailing whitespace / EOF / merge conflict / private key / AWS credentials; `pre-commit-terraform` (`terraform_fmt`, `terraform_docs`, `terraform_tflint` with selected rules, `terraform_validate` excluding `docs|modules`) |
| Why it matters | Enforces formatting, spelling, Terraform hygiene before merge |
| Notable details | TFLint limited to named rules only; validate skips `docs` and `modules` |

### cspell.config.yaml

| Field | Detail |
|---|---|
| What it is | CSpell dictionary wiring |
| What it contains / does | Defines `bpWords` dictionary from `./docs/cSpell_dict.txt` and enables it |
| Why it matters | Avoids false spellcheck failures on K8s/AWS jargon |
| Notable details | Companion word list lives under `docs/` even though config is at root |

### mkdocs.yml

| Field | Detail |
|---|---|
| What it is | MkDocs site configuration |
| What it contains / does | Site name Amazon EKS Blueprints for Terraform; Material theme (orange, Ember font, logos under `images/`); plugins `include-markdown`, `search`, `awesome-pages`; hook `.github/scripts/mkdocs-hooks.py`; `mike` version provider; markdown extensions (admonition, highlight, snippets, superfences, toc permalinks); docs from `docs/`; site URL `https://aws-ia.github.io/terraform-aws-eks-blueprints/` |
| Why it matters | Controls published documentation look, nav plugins, and build hooks |
| Notable details | Sticky nav tabs; copyright Amazon 2024 |

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
