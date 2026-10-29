# Investigation

| Alert | Splunk check |
|---|---|
| Alfrescoacr batch | Host count not 4. Index `alfrescoacr-batch`. |
| Agrex | Host count not 1. Index `agrex`. |
| Alfrescoacr | Host count not 3. Index `alfrescoacr`. Screen DQL also excludes `alfrescoacr-batch`. |
| Alfrescocollabsrv | Host count not 1. Index `alfrescocollabsrv`. |
| BillingCenter batch | Host count not 2. Index `bc2-batch`. |
| PolicyCenter batch | Host count not 2. Index `pc2-batch`. |
| BillingCenter UI | Host count not 2. Index `bc2-ui`. |
| Contact Manager UI | Host count not 2. Index `cm2-ui`. |
| Mail service | Host count not 1. Index `mailservice`. |
| BAU-4050 | Events in `pc2-batch` that contain the payment-request exception sentence. |
| Reimbursement check | Events in `bc2-ui` that contain `errcode=E0105errinfo=E010500004`. |

The screen DQL used `count()` by name. That number is log lines. Splunk `Message` is the number of names.
