# Dynatrace Log Path Gap

```
Chat: is /app/ICM_CPW/log/ap/default.log collected?
  three ICM claim-payment hosts → yes, already in Terraform
  CEAA20F7 → no
    its host group is HOST_GROUP-9034BF4FC7D158B2
    the note asks main.tf to add two resources on that group
      log storage → keep matching lines
      custom log source → tell the agent to read the file
  before apply
    does this FileNet host actually write that ICM log?
    a host-group rule hits every host in the group
    this chat is about PII masking, and the mask rule is not in the note
```

```
/app/ICM_CPW/log/ap/default.log
        |
        +--> CEAAI016, CEAA9026, CEAA9027
        |      Terraform already includes the path
        |      agent reads the file
        |      lines go to Dynatrace storage
        |
        +--> CEAA20F7
               path is not in its host group today
               proposed main.tf
                 custom log source on HOST_GROUP-9034BF4FC7D158B2
                 log storage MATCHES that path
                 send_to_storage = true
```
