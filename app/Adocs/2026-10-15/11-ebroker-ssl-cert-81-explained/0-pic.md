# Ebroker SSL Cert 81 Pic

```
#81: is the ebroker cert ending within 30 days?
 Splunk: makeresults → lookup sslcert_lookup → where < now + 30d
 Dynatrace: no table by default
  → Option B Synthetic monitor (recommended)
  → Option A load uploaded CSV
```

```
Synthetic location → HTTPS ebroker → certificate → < 30 days → problem → alert
```
