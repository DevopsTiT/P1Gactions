# Cisco VPN LDAP Explained Result

| Point | What it means |
|---|---|
| Same goal | Both alert when the VPN cannot reach Windows LDAP. |
| Old rule was silent | More than 3 lines per minute never happened. |
| New rule | Any matching line in the last 5 minutes opens a problem. |
| One problem per file | Identity field `log.source`. |
| Paging | Workflow pages because `pagerduty.enabled = "1"`. |
| Next step | Run check queries from answer 20, then `terraform validate` and `plan`. |
