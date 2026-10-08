# Claims Auto-Assessment API Error Pic

```
pods claims-auto-assessment-api-*
 → line contains "] ERROR "?
   no  → ignore
   yes → contains "Error stacktraces are turned on"?
          yes → ignore (startup notice)
          no  → row → 1 problem (check) → high, email only
 no errors for 10 min → problem closes
```
