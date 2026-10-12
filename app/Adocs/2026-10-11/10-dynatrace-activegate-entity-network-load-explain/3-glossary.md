# ActiveGate Entity And Process Network Load Glossary

| Term | What it means | Why you care |
|---|---|---|
| ActiveGate | Dynatrace relay and remote-check server. | Cell V looks for them. |
| dt.entity.apm_security_gateway | Classic entity table for ActiveGates. | The right table to use. |
| Network zone | Setting that routes agents to nearby ActiveGates. | Not the same as tags. |
| eastasia | Azure region name for East Asia. | The filter text. |
| caseSensitive:false | Makes contains ignore upper and lower case. | Avoids missed matches. |
| queryId comment | Note showing which Dynatrace page a query came from. | Origin of cell X. |
| dt.process.network.load | Network load metric of a process. | Charted in cell X. |
| arrayMax | Largest value in a series. | Finds the spike. |
