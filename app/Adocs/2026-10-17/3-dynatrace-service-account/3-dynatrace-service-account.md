# Dynatrace Service Account

## Decision tree

```
Heard "service account" in Dynatrace?
 Latest Dynatrace (IAM / Account Management)?
   → they mean a service user: a non-human identity for scripts, CI, workflows
   → attach a platform token OR an OAuth client (client credentials) to it
 Classic environment API token only?
   → that is not a service account; it is an old-style access token with scopes
 Kubernetes "service account"?
   → different thing (K8s / IRSA). Not Dynatrace IAM.
 Need automation that must not die when a person leaves?
   → put the token on a service user, not on your personal user
 Need short-lived machine tokens?
   → OAuth client credentials → SSO token endpoint → Bearer access_token
 Need simple long-lived Bearer for platform APIs?
   → platform token assigned to the service user
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | A **service user**: a Dynatrace identity for machines, not for a person logging into the UI. |
| Why use it? | Automation keeps working when people leave. Permissions and audit stay on the bot identity. |
| How does it authenticate? | Usually a **platform token** or an **OAuth client** bound to that service user. |
| Same as classic API token? | No. Classic `apiTokens` are environment tokens. Service users live at **account** IAM. |
| Same as K8s service account? | No. That is Kubernetes. |

## Summary

In Latest Dynatrace, a service account means a **service user**: an account-level robot identity used by Terraform, CI, workflows, and scripts. You give that user permissions (through groups/policies), then create a platform token or OAuth client that acts as that user. Prefer this over putting automation tokens on your personal login.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Service user / service account | Non-human Dynatrace identity for automation. | The "who" that calls APIs when no person is logged in. |
| Platform token | Long-lived Bearer token for platform APIs. | Can be owned by you or by a service user. |
| OAuth client | Client ID + secret that can request short-lived tokens. | Better for machine-to-machine with short expiry. |
| Classic access token | Old environment API token (`v2/apiTokens`). | Still common for ingest and older Env APIs. |
| Scope | Named permission on a token (for example read logs). | Token cannot do more than its scopes allow. |
| Account | Dynatrace billing / IAM boundary that holds many environments. | Service users and platform tokens are account-scoped. |
| Environment | One Dynatrace tenant URL (for example `abc12345.live.dynatrace.com`). | Where OneAgents and classic tokens often live. |

### What a service account is (plain English)

Think of three kinds of "who" in Dynatrace:

| Who | Human? | Typical use |
|---|---|---|
| You (regular user) | Yes | Click UI, maybe personal scripts |
| Service user (service account) | No | CI, Terraform, workflow bots, integrations |
| Classic API token | No person attached | Older Env API / ingest style access |

A service user looks a bit like a user (email-like id such as `something@service.sso.dynatrace.com`), but nobody logs into the browser as that user for daily work. Scripts act **as** that user.

### How it fits with tokens

```
Service user (identity + permissions via groups/policies)
   │
   ├── Platform token  ──► Authorization: Bearer <dt0s01....>
   │         long-lived, good for scripts and internal tools
   │
   └── OAuth client (client_id + client_secret)
             │
             ▼
        POST https://sso.dynatrace.com/sso/oauth2/token
             grant_type=client_credentials
             │
             ▼
        short-lived access_token → Authorization: Bearer <access_token>
```

| Credential | Bound to | Lifetime | Best for |
|---|---|---|---|
| Platform token on service user | Service user permissions + token scopes | Long (you set / manage expiry) | Simple automation on platform APIs |
| OAuth client credentials | Client scopes; often tied to a subject service user | Access token short (minutes) | Enterprise / rotating secrets |
| Classic env API token | Environment scopes only | Until revoked | Log ingest, older Env API, OneAgent installers |

Important rule from Dynatrace docs: a platform token only works if the **assigned user still has the permissions**. Scopes on the token are not enough by themselves.

### What you use a service account for

| Use case | Why a service user helps |
|---|---|
| Terraform applying Davis detectors | Token does not vanish when an engineer leaves |
| CI calling platform / Grail APIs | Audit shows the bot, not a person |
| Workflows or apps calling Dynatrace APIs | Stable identity with least privilege |
| Several people share one automation token limit | Platform tokens on a service user use the service-user quota (up to 100), not your personal 50 |

### How it is set up (high level)

| Step | Who | What |
|---|---|---|
| 1 | Account admin | Create the service user in Account Management / IAM |
| 2 | Account admin | Put the service user in groups with the right policies (least privilege) |
| 3 | Account admin | Grant humans `iam:service-users:use` if they may mint tokens for that service user |
| 4 | Allowed user | Create a **platform token** assigned to that service user, with needed scopes |
| 5 | Or admin | Create an **OAuth client** (client credentials) for machine flow |
| 6 | Automation | Call APIs with `Authorization: Bearer ...` |

Optional modern pattern: **workload identity federation** maps GitHub Actions / Entra / GCP identity to a service user so you do not store a Dynatrace secret in the pipeline.

### Service account vs other Dynatrace credentials

| Thing | Is it a service account? | Notes |
|---|---|---|
| Service user | Yes (this is what people mean) | Account-level robot user |
| Platform token | No | Credential that can belong to a service user |
| OAuth client | No | Credential that can act for automation / a user |
| Classic access token | No | Environment token; different model |
| Dynatrace Operator K8s SA | No | Kubernetes service account for the Operator pod |
| IRSA | No | AWS IAM role for a K8s service account |

### Common mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| Put CI token on your personal user | Breaks when you leave; eats your token quota | Assign token to a service user |
| Token scopes without user permissions | HTTP 403 | Grant the service user the IAM policies first |
| Expect classic env token to be a service account | Wrong model | Use service user + platform token / OAuth for platform APIs |
| Commit client_secret or platform token to Git | Leak | Secret store / CI secrets only |
| Confuse with Kubernetes SA | Wrong docs | Dynatrace IAM ≠ K8s SA |

## Result

| Remember | Detail |
|---|---|
| Definition | Service account ≈ **service user**: non-human Dynatrace identity for automation |
| Auth | Platform token or OAuth client credentials acting as that user |
| Not the same as | Classic API token, K8s service account, IRSA |
| Practice | Least privilege groups; rotate secrets; never commit tokens |

## Data flow map

```
Human admin
  → creates service user + group policies
  → creates platform token OR OAuth client for that user
       │
       ▼
CI / Terraform / script
  → Bearer token (platform token, or short-lived OAuth access_token)
  → Dynatrace platform / environment APIs
       │
       ▼
Audit / IAM sees actions as the service user
```

## Related files

| File | Purpose |
|---|---|
| `3-dynatrace-service-account.md` | This answer |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Docs sources |
| `2-result.md` | What to do |
| `3-glossary.md` | Terms |
| `3.sh` | Example curl shapes and git one-liners (not run) |
| Dynatrace docs | Platform tokens, OAuth clients, token concepts |

## Commands

See `3.sh`. None of these commands have been run. Replace placeholders. Never put real tokens in committed files.

```
curl --request POST "https://sso.dynatrace.com/sso/oauth2/token" --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "grant_type=client_credentials" --data-urlencode "client_id=$DT_CLIENT_ID" --data-urlencode "client_secret=$DT_CLIENT_SECRET" --data-urlencode "scope=storage:logs:read" --data-urlencode "resource=urn:dtaccount:$DT_ACCOUNT_UUID"
curl --request GET "https://$DT_ENV_ID.apps.dynatrace.com/platform/..." --header "Authorization: Bearer $DT_PLATFORM_TOKEN"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/3-dynatrace-service-account
git commit -m "dynatrace service account explained"
git push
```
