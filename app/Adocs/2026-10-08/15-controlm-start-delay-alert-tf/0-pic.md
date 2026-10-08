# Control-M Start Delay Alert Pic

```
"Start Time Delay" in controlm_alert?
  no  -> no problem
  yes -> lookups (addresslist, job_definition, specific_contact)
         -> JOB_CODE = job_name + current_time
         -> one problem per JOB_CODE (medium, pagerduty 0)
```

```
Control-M -> controlm_alert log -> Grail -> Records detector (5m)
  -> + 3 lookups -> MailTitle / MailBody -> problem -> workflow -> email
```
