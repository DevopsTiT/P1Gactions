# Result

| Outcome | Detail |
|---|---|
| OPEN updated | Sends Environment, Business service EIP, Category, Subcategory, Impact and Urgency labels, Assignment group (L1 or L2), and a customer notes block. PagerDuty gets the same details. |
| CLOSE updated | Close notes and customer notes carry cause, duration, service, application, dashboard and links. |
| Structure | Same tasks, positions, parallel posting and sync keys as Sep 24. |

## Next steps

| Step | Why |
|---|---|
| Replace `__EIP_L2_GROUP__`, `__EIP_L3_GROUP__`, `__EIP_DASHBOARD_URL__`, `__PD_SERVICE_URL__` | Otherwise the placeholder text shows in notes and L2 routing fails. |
| Run the label checks in `6.sh` | Impact labels "1 - Critical" and "2 - High" are guesses. |
| Trigger a test Problem and read `notFilled` | Confirms every field was accepted. |
