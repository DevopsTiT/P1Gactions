# Pic

```
INC30339599 blanks: Environment, Business service, Category, Subcategory, Assignment group, CI; Contact type Phone
Why: "*" is form-only; API skips it
Fix: each field → CMDB → tag → zone map → DEFAULT (+ gap note)
     empty mandatory → STOP
     POST ?sysparm_input_display_value=true
     read back → rejected values → work note
```
