# EIP MQ And AGPO Auth0 Pic

```
eip_mq_conn_timeout
 host wpalja21b* → "Connection timed out" in last 2 min? → yes → medium, email

agpo_auth0_password_sync_error
 agpo auth pods → BadRequest or NotFound password errors in last 5 min
   count > 1? → yes → high, PagerDuty
              → no  → nothing
```
