# Investigation

User asked for the Dynatrace workflow again using the **ServiceNow connector** (Connection + `snow-*` actions).

Checked:

| Source | Finding |
| --- | --- |
| Seq 13 / 17 packs | Authoritative Connector open/close YAML |
| Seq 15 | PD-only; classic notification owns INC |
| Seq 18 | JS REST mimic — not Connector |

Conclusion: re-deliver Connector pack as seq 19 with the same working YAML.
