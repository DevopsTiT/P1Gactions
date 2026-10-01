# Close Trigger Pic

```
Trigger: active or closed (no "closed only" option)
   ▼
prepare-close → is_closed?
   no  → close-silva-incident skip, close-pagerduty skip
   yes → resolve INC (incident_state) + resolve PD
```
