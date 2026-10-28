# PagerDuty AI Security Questionnaire

```
Security pre-questionnaire for PagerDuty AI
  1 login → [X] SSO and [X] MFA
            SAML to the company identity provider
            MFA is enforced there before login
  2 vendor stores the incident → [X] Yes
  3 transit → encrypted, published minimum TLS 1.2
            do not tick TLS 1.3
            do not tick No
  4 storage → [X] Yes, AES-256
```

| Key point | Detail |
|---|---|
| Login | Single sign-on with SAML, and multi-factor authentication on that same login. |
| Where data sits | In PagerDuty’s cloud, in the region set on the account. |
| Transit | TLS 1.2 or higher. The form’s TLS 1.3 box is not ticked. |
| Disk | AES-256. |

## Summary

Tick SSO and MFA, and tick Yes for vendor storage and for encrypted storage. Leave the TLS 1.3 box empty and write the vendor’s real line next to it: TLS 1.2 or above. Do not tick No on question 3. That box means the product cannot be used, and the path is encrypted.

## Investigation

| Source | What it shows |
|---|---|
| PagerDuty SSO docs | SAML 2.0 to an identity provider such as Microsoft Entra ID or AD FS. Plans include Professional, Business, and Enterprise. The account owner turns it on. |
| Identity-provider MFA guides | MFA is applied by the identity provider before the SAML login is accepted. |
| PagerDuty GDPR statement | Encryption in transit at least TLS 1.2 or above. Encryption at rest at least AES-256. Customers can choose the service region. |
| Webhook TLS note | One delivery path is documented as TLS 1.2. That is why TLS 1.3 is not ticked as the only version. |
| This use case | The incident, the Teams prompt, and the runbook text are the data that reaches PagerDuty AI. |

## Result

Paste this into the Response column.

```
1) MFA or SSO
[X] MFA
[X] SSO
[ ] No

SSO is SAML 2.0 to the company identity provider (Microsoft Entra ID).
MFA is required on that identity provider before the SAML login succeeds.
After SSO is tested, turn off username-and-password login on the PagerDuty account.
The account owner configures SSO under Account Settings → Single Sign-On.
SSO is available on Professional, Business, and Enterprise plans. Confirm the current plan includes it.

2) Does the AI service store AXA data in the vendor environment
[X] Yes
[ ] No

PagerDuty is SaaS. The incident record and the text sent to PagerDuty AI are processed and stored in PagerDuty’s cloud, in the service region configured on the account.
Confirm that region with the account owner before the meeting.
Model providers used by the assist are named in the PagerDuty Advance AI Disclosure. Attach that document. PagerDuty states it does not train its models on customer data.

3) Is the network used for storing data encrypted
[ ] TLS 1.3
[ ] No

Do not tick No. The path is encrypted.
Do not tick TLS 1.3. PagerDuty’s public statement is encryption in transit using at least TLS 1.2 or above, not TLS 1.3 only.
Write this sentence in the cell: Transit encryption is TLS 1.2 or higher (PagerDuty security statement).

4) Are storage and databases encrypted
[X] Yes
Algorithm: AES-256. PagerDuty states encryption at rest of at least AES-256.
[ ] No
```

## Data flow map

```
[Person] → MFA at company identity provider → SAML → [PagerDuty]
                                                      |
[Incident + Teams prompt] → TLS 1.2 or higher → stored AES-256
                                                      |
                                                      v
                                            PagerDuty AI reply
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/12-pagerduty-ai-input-data/` | What data this questionnaire covers. |
| `Daily Files/2026-10-28/5-pagerduty-ai-gate0-page3/` | Product name and the AI disclosure. |
| `13.sh` | Copy and git one-liners. Review before running. |

## Commands

See [13.sh](13.sh). Do not commit or push until you ask for that.
