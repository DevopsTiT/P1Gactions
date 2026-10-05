# Datalake Batch Result Picture

## Decision Tree

```
daily list of lines → report → scheduled workflow
 empty email? → fix log.source (check.dql 1)
 > 500 lines? → raise limit (check.dql 3)
 seq 29 applied? → do not apply 42 too
```

## Data Flow

```
08:00 JST → fetch logs since 00:00 JST → any lines? → email / skip
```
