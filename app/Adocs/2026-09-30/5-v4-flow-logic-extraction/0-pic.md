# V4 Flow Pic

```
event ──► TASK 1 extract ──► TASK 2 SILVA GET ──► TASK 3 preview
             │                    │                   │
             │ tags split         │ group sys_id      │ ready_for_snow
             │ group candidates   │ CI lookup         │ decision
             │ environment        │ service search    │ SNOW body
             │ maintenance        │ offering          │ PagerDuty body
             │ host and DB        │                   │
```

```
GROUP:   GROUP_MAP → tag (checked) → tag (unchecked) → service → CI → default
SERVICE: SERVICE_MAP → service tag → CI link → scored search → candidates
```
