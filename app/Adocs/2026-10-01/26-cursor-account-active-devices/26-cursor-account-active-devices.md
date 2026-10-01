# Cursor Account Active Devices

## Decision tree

```
Want to see devices using my Cursor account?
  open cursor.com/dashboard → My Settings → Active Sessions
    session you recognize      → keep
    session you do not know    → Revoke
  suspect compromise?
    secure login first (Google/GitHub password + 2FA, or email account)
    then revoke sessions
    check cursor.com/dashboard/billing for unknown charges
    still wrong → security@cursor.com
  login through company SSO? → IT admin revokes in the identity provider
```

## Short takeaway

| Question | Answer |
|---|---|
| Can the agent see my devices? | No. The agent has no access to account session data. |
| Where is the list? | cursor.com/dashboard, My Settings, Active Sessions. |
| How to sign one out? | Click Revoke next to that session. |
| Sign out all at once? | The docs only describe revoking one session at a time. |
| Using company SSO? | Your IT admin revokes sessions in the identity provider. |

## Summary

Cursor lists logged-in sessions in the web dashboard under Active Sessions. Review the list and revoke anything you do not recognize. If you think the account was compromised, secure the login method first, then revoke.

## Steps

| Step | Action |
|---|---|
| 1 | Open https://cursor.com/dashboard and sign in. |
| 2 | Click My Settings. |
| 3 | Scroll to Active Sessions. |
| 4 | Click Revoke next to any unknown session. |

## If you suspect a compromise

| Step | Action |
|---|---|
| 1 | Secure the login method: change the Google or GitHub password and turn on 2FA, or secure the email account for magic links. |
| 2 | Revoke unknown sessions. |
| 3 | Check https://cursor.com/dashboard/billing for charges you do not recognize. |
| 4 | Contact security@cursor.com for unknown charges, lost access or exposed API keys. |

## Data flow

```
browser → cursor.com/dashboard → My Settings → Active Sessions → Revoke
```

## Related files

| File | Purpose |
|---|---|
| `26.sh` | Link and copy commands. |

Source: https://cursor.com/help/security-and-privacy/account-compromised

## Commands

See `26.sh`.
