# Glossary

| Term | What it means | Why you care on this slide |
|---|---|---|
| Volume | The work the assist applies to. | Here, one critical PagerDuty incident is one unit. |
| Adoption rate | Share of those incidents that received an accepted Teams catch-up. | The adoption KPI. |
| Clock A | Minutes from acknowledge until a reviewer accepts a hand-written catch-up. | The current way of working. |
| Clock B | Minutes from the Teams question until the reviewer accepts the AI reply. | The assisted way. |
| 3 minutes | The PoC limit for Clock B after the question. | A pass rule, not a number measured in production. |
| 50% | Clock B must be at most half of Clock A on the median. | The other pass rule. |
| 80% | Share of pilot-service incidents with a catch-up in the first 90 days. | The production adoption target. |
| Median | The middle value of the set. | One unusual incident does not set the KPI. |
| FTE | Headcount implied by hours saved. | Fill it only after minutes and the monthly incident count are both known. |
