# Investigation

| What was checked | Finding |
|---|---|
| Source | `index=jenkins_statistics sourcetype="json:jenkins:old"` |
| Jobs | `applications*` and `group-jobs*` |
| Application filter | `pager_duty="0"` only |
| Logic | Last 2 runs, NG without SUCCESS, recovery on OK after NG |
| Schedule | Every minute, Last 120 minutes |
| Action | Alert Status Manager, Production email, PagerDuty Disable |
| Index content | Host ceaa2099; many audit_trail events mixed in |
| Not visible | Macro definitions |
