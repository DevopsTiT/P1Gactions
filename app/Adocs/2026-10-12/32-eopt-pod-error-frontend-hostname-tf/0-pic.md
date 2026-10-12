# eopt Pod Error Frontend Pic

## Decision tree

```
host.name starts with eoptfrontend-
 parse JSON → upper(level) == ERROR → problem medium → email
 loglevel already set? → filter loglevel instead
 answer 31 → remove eoptfrontend- line
```

## Data flow

```
frontend pods → JSON logs → Grail → detector (1 h) → problem → workflow → email
```
