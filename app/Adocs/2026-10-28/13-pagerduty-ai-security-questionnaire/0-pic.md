# Pic

```
Security
  1 [X] SSO   [X] MFA
      SAML + MFA at the company login
  2 [X] Yes   data is stored at PagerDuty
  3 transit   TLS 1.2 or higher
      leave TLS 1.3 blank
      leave No blank
  4 [X] Yes   AES-256
```

```
[MFA] → [SAML] → [PagerDuty]
                     |
                     +-- TLS 1.2+ on the wire
                     +-- AES-256 on disk
```
