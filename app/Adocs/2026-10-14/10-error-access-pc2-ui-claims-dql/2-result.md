# Error Access And PC2 UI Claims Result

## SPL #11 and #12

```
fetch logs, from:now()-1h
| filter matchesPhrase(content, "error")
    or matchesPhrase(content, "failed")
    or matchesPhrase(content, "severe")
    or (
         startsWith(log.source, "access_")
         and (matchesPhrase(content, "404") or matchesPhrase(content, "500") or matchesPhrase(content, "503"))
       )
| sort timestamp desc
| fields timestamp, host.name, log.source, loglevel, content
```

## SPL #13

```
fetch logs, from:now()-24h
| filter contains(log.source, "pc2-ui", caseSensitive:false)
    or contains(k8s.container.name, "pc2-ui", caseSensitive:false)
    or startsWith(k8s.pod.name, "pc2-ui")
| filter contains(content, "esbv4-inssuite-prod", caseSensitive:false)
    and contains(content, "/esb/legacyclaims/services/legacydata/claims", caseSensitive:false)
| filter matchesPhrase(content, "FAIL")
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

Run the check queries in the `.dql` file first if either returns 0 rows.
