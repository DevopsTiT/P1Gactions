# First Answer Fallback Pic

```
service empty?
 ├─ assignment_group.nameLIKE group → rows? → env match or first row
 ├─ support_group.nameLIKE group   → rows? → env match or first row
 ├─ nameLIKE trigram               → rows? → env match or first row
 ├─ nameLIKE db type               → rows? → env match or first row
 └─ DEFAULT_BUSINESS_SERVICE
```

```
offering: service + env → service first → group + env → group first → default
company:  service → CI → group → DEFAULT_COMPANY
```
