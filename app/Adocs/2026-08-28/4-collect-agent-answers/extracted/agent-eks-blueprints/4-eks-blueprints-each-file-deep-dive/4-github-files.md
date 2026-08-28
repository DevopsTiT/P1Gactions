# GitHub Files Deep Dive

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
| Scope | File-by-file deep dive for **GitHub Files Deep Dive** |
| Source | terraform-aws-eks-blueprints-main |

## Summary

### .github/CODEOWNERS

| Field | Detail |
|---|---|
| What it is | CODEOWNERS file |
| What it contains / does | `* @aws-ia/internal-terraform-eks-admins` |
| Why it matters | Routes review ownership for all paths |
| Notable details | Single team owns everything |

### .github/dependabot.yml

| Field | Detail |
|---|---|
| What it is | Dependabot config |
| What it contains / does | Daily updates for `github-actions` ecosystem at `/` |
| Why it matters | Keeps Actions versions current |
| Notable details | Actions only (no npm/pip/terraform ecosystem entries here) |

### .github/PULL_REQUEST_TEMPLATE.md

| Field | Detail |
|---|---|
| What it is | PR description template |
| What it contains / does | Description; Motivation (`Resolves #`); test checklist (local test, docs update, `pre-commit run -a`); Additional Notes |
| Why it matters | Standardizes PR quality bar |
| Notable details | Warns to open an issue before significant work |

### .github/ISSUE_TEMPLATE/config.yml

| Field | Detail |
|---|---|
| What it is | Issue template config |
| What it contains / does | `blank_issues_enabled: false` |
| Why it matters | Forces structured issue forms |
| Notable details | No free-form blank issues |

### .github/ISSUE_TEMPLATE/bug_report.md

| Field | Detail |
|---|---|
| What it is | Bug report template |
| What it contains / does | Requires executable reproduction (`terraform init && apply`); search checkbox; cache clear steps; module/TF/provider versions; expected vs actual; screenshots |
| Why it matters | Makes bugs actionable for maintainers |
| Notable details | Mentions `examples/*` (historical naming; repo uses `patterns/`) |

### .github/ISSUE_TEMPLATE/feature_request.md

| Field | Detail |
|---|---|
| What it is | Feature request template |
| What it contains / does | Community Note (vote with reactions, no +1 noise); outcome, proposed solution, alternatives, context |
| Why it matters | Prioritizes features with signal, not comment spam |
| Notable details | Standard AWS terraform-module style community note |

### .github/ISSUE_TEMPLATE/question.md

| Field | Detail |
|---|---|
| What it is | Question issue template |
| What it contains / does | Search checkbox; question body; link to related example/module; context |
| Why it matters | Separates Q&A from bugs/features |
| Notable details | Asks for repo example link |

### .github/workflows/linkcheck.json

| Field | Detail |
|---|---|
| What it is | markdown-link-check config |
| What it contains / does | 5s timeout; retry on 429 (5×, 30s fallback); alive 200/206; special Accept-Encoding for help.github.com; ignore localhost/127.0.0.1 |
| Why it matters | Reduces flaky link CI failures |
| Notable details | Consumed by `markdown-link-check.yml` |

### .github/scripts/mkdocs-hooks.py

| Field | Detail |
|---|---|
| What it is | MkDocs build hook |
| What it contains / does | `on_page_markdown` (attempted path replaces; return markdown); `on_files` copies assets from pattern dirs into site (targeted-odcr screenshots, kubecost screenshot, ml-container-cache svg/png) |
| Why it matters | Makes pattern assets appear under docs URLs without duplicating into `docs/` |
| Notable details | `markdown.replace` results are not assigned back (no-op for markdown path rewrites) |

### .github/scripts/delete-log-groups.py

| Field | Detail |
|---|---|
| What it is | CI cleanup helper |
| What it contains / does | boto3 Logs client; deletes log groups prefixed `/aws/eks/` (up to 50 listed) in `AWS_DEFAULT_REGION` (default `us-west-2`) |
| Why it matters | Clears leaked EKS CW log groups before e2e runs |
| Notable details | Used by `e2e-parallel-full.yml` prereq job |

### .github/scripts/iam-policy-generator.py

| Field | Detail |
|---|---|
| What it is | IAM policy merger for e2e |
| What it contains / does | Reads all JSON policy objects from S3 bucket `BUCKET_NAME`; unions Action lists; prints Allow `Resource: "*"` skeleton policy |
| Why it matters | Builds aggregate IAM policy from iamlive captures across examples |
| Notable details | Needs `BUCKET_NAME` env; used post-deploy in e2e-full |

### .github/scripts/plan-examples.py

| Field | Detail |
|---|---|
| What it is | Discovers pattern directories for plan matrix |
| What it contains / does | Glob `patterns/**/main.tf`; exclude certain paths (appmesh-mtls, blue-green subdirs, istio-multi-cluster parts, privatelink-access); prints JSON array |
| Why it matters | Feeds `plan-examples.yml` matrix dynamically |
| Notable details | Skips paths matching `^.+/_` |

### .github/workflows/publish-docs.yml

| Field | Detail |
|---|---|
| What it is | Docs publish workflow |
| What it contains / does | On push to `main`: harden-runner; checkout; Python; pip install pinned mkdocs-material + include-markdown + awesome-pages; `mkdocs gh-deploy --force` |
| Why it matters | Publishes GitHub Pages docs site |
| Notable details | Pins plugin versions; contents write for gh-pages |

### .github/workflows/pre-commit.yml

| Field | Detail |
|---|---|
| What it is | Pre-commit CI on PRs |
| What it contains / does | Triggers on `**.tf`/`**.yml`/`**.yaml` to main; concurrency cancel; TF 1.3.10, terraform-docs v0.19.0, tflint v0.53.0; paths-filter for `*.tf`; composite pre-commit action when TF changed |
| Why it matters | Enforces same hooks as local pre-commit in CI |
| Notable details | Job name “Min TF pre-commit”; YAML-only changes may not run TF hooks if `src` filter false |

### .github/workflows/pr-title.yml

| Field | Detail |
|---|---|
| What it is | Semantic PR title validator |
| What it contains / does | `pull_request_target` opened/edited/synchronize; `amannn/action-semantic-pull-request`; subject must start uppercase; WIP allowed; no required scope |
| Why it matters | Keeps conventional/consistent PR titles |
| Notable details | Uses `pull_request_target` (runs in base context) |

### .github/workflows/plan-examples.yml

| Field | Detail |
|---|---|
| What it is | Manual terraform plan across patterns |
| What it contains / does | `workflow_dispatch` only; environment `EKS Blueprints Test`; only on `aws-ia/terraform-aws-eks-blueprints`; matrix from `plan-examples.py`; OIDC AWS us-west-2; terraform 1.0.0 init/plan per changed directory |
| Why it matters | Cheap validation that examples still plan |
| Notable details | Comments warn against checking out untrusted PR code for the python discovery step |

### .github/workflows/stale-issue-pr.yml

| Field | Detail |
|---|---|
| What it is | Stale issue/PR automation |
| What it contains / does | Daily cron + dispatch; stale after 30 days, close after 10 more; exempt `bug`/`enhancement`; custom messages |
| Why it matters | Keeps issue tracker from rotting |
| Notable details | Uses `actions/stale@main` |

### .github/workflows/e2e-parallel-full.yml

| Field | Detail |
|---|---|
| What it is | Full e2e apply/destroy matrix |
| What it contains / does | Manual dispatch with `TFDestroy` input (default true); prereq deletes `/aws/eks/` log groups; matrix of 7 patterns; uncomment remote backend; iamlive CSM capture; staged terraform apply/destroy targets; upload per-example policy JSON to S3; post job merges via `iam-policy-generator.py` |
| Why it matters | Real AWS validation of selected blueprints |
| Notable details | Patterns: agones, fargate, getting-started-argocd, ipv6, karpenter, multi-tenancy, stateful |

### .github/workflows/e2e-parallel-destroy.yml

| Field | Detail |
|---|---|
| What it is | Destroy-only e2e workflow |
| What it contains / does | Same pattern matrix as full e2e; OIDC; enable backend; staged destroy (addons → eks → all); no apply/iamlive |
| Why it matters | Cleanup stuck e2e state without re-applying |
| Notable details | Workflow name in file: `e2e-parallel-destroy-only` |

### .github/workflows/dependency-review.yml

| Field | Detail |
|---|---|
| What it is | PR dependency vulnerability review |
| What it contains / does | On pull_request; harden-runner; checkout; `dependency-review-action` (pinned SHAs) |
| Why it matters | Blocks known-vulnerable dependency bumps when required |
| Notable details | Comments explain required-check behavior |

### .github/workflows/scorecards.yml

| Field | Detail |
|---|---|
| What it is | OpenSSF Scorecard supply-chain analysis |
| What it contains / does | On branch protection, weekly Tuesday cron, push to main; scorecard-action SARIF; publish_results true; upload artifact + code scanning |
| Why it matters | Continuous supply-chain security score |
| Notable details | `permissions: read-all` default; security-events + id-token for upload/publish |

### .github/workflows/markdown-link-check.yml

| Field | Detail |
|---|---|
| What it is | Markdown link checker |
| What it contains / does | On push/PR to main when `**.md` changes; Node 20; `markdown-link-check@3.12.2`; runs on all `docs/**/*.md` with `linkcheck.json` |
| Why it matters | Prevents broken links in published docs |
| Notable details | Only scans `docs/`, not all repo markdown |

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
