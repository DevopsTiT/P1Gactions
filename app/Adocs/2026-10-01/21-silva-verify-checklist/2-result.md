# SILVA Verify Result

| Step | What to do | Pass condition |
|---|---|---|
| A | Run `21.sh` lines 1 to 7 | Every record exists and is active, the service is not an offering, and the offering parent is the service. |
| B | Run line 8 | impact 4, urgency 4, event and other are valid choices. |
| C | Run line 9 | No open incident before the first POST. |
| D | Run OPEN v7 once on stg, then line 10 | Every field read back matches the payload. |

Send the outputs of lines 5 and 10 to confirm the environment fallback and the end-to-end mapping.
