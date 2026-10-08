# Separate Terraform Files Pic

```
seq 6: 1 file, for_each, 2 keys
 → seq 7: 3 files, same folder
    providers.tf
    eip-mq-conn-timeout.tf            → eip_mq_conn_timeout
    agpo-auth0-password-sync-error.tf → agpo_auth0_password_sync_error
 seq 6 applied? → terraform state mv first → plan shows no changes
```
