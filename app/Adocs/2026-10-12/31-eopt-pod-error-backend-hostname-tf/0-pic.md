# eopt Pod Error Host Name Pic

## Decision tree

```
host.name starts with eoptsystemapi- / eoptprocessapi- / eoptfrontend-
 parse level → ERROR → problem per service (medium) → email
 backend only? → remove eoptfrontend- line
```

## Data flow

```
eopt pods → Grail (host.name = pod) → detector (1 h, ERROR) → problem → workflow → email
```
