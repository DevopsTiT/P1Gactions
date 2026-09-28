# Open Close Example Fields And Testing Group

Mirror of CursorFiles `Daily Files/2026-09-28/7-open-close-example-testing-group/7-open-close-example-testing-group.md` (the full version is there).

## Decision tree

```
Make the workflow ticket look like example INC30339566
 Short description   → "[DYNATRACE JAPAN][<host>] - <title>"
 Summary             → "<title>" + "Additional Information:" + JSON block
 Contact type        → Event
 Company             → AXA GROUP OPERATIONS
 Business service    → Third Party Services Monitoring Application
 Service offering    → Third Party Services Monitoring Application
 Configuration item  → host name
 Environment         → tag AGO_AXAENVIRONMENTNAME
 Category / Sub      → Other / Other
 Impact / Urgency    → custom alert = 4 - Low
 Assignment group    → "testing 3122" while testing; "" later → tag AGO_AXA_SUPPORTGROUP → L1/L2
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed in OPEN? | Field values copy the example ticket; the assignment group is forced to "testing 3122". |
| What changed in CLOSE? | Only the business service name in the notes. |
| Is the structure the same? | Yes. Same tasks, positions, parallel posts, sync keys. |
| How do I switch off the test group? | Set `TEST_ASSIGNMENT_GROUP = ""`. |

## Example field to workflow field

| Example field | Example value | OPEN sends |
|---|---|---|
| Contact type | Event | `contact_type` |
| Company | AXA GROUP OPERATIONS | `company` |
| Environment | Development | `u_environment` from tag `AGO_AXAENVIRONMENTNAME` |
| Business service | Third Party Services Monitoring Application | `business_service` |
| Service offering | Third Party Services Monitoring Application | `service_offering` |
| Configuration item | ts12.hk.intraxa | `cmdb_ci` from host |
| Category | Other | `category` |
| Subcategory | Other | `subcategory` |
| Impact | 4 - Low | `impact` for custom alerts |
| Urgency | 4 - Low | `urgency` for custom alerts |
| Assignment group | InfraSupport_Dist-WindowsHK_L2_ASIA | `assignment_group` = testing 3122 |
| Short description | [DYNATRACE JAPAN][TS12.hk.intraxa] - ... | `short_description` |
| Summary | title + Additional Information JSON | `description` |

## Things to know

| Point | Why it matters |
|---|---|
| Group name must match exactly | A non-matching name is dropped; check `notFilled`. |
| Remove the test group before go-live | Otherwise real alerts go to testing 3122. |
| correlation_id stays the problem ID | CLOSE needs it to find the ticket. |

## Related files

| File | What it is |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | Updated OPEN |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | Updated CLOSE |
| `7.sh` | Diff and SILVA checks |
