# Datalake Detector Picture

## Decision Tree

```
terraform + provider → plugin and login
resource detector
  query   → lines per minute
  rule    → > 0, 1 of 5 minutes opens, 60 quiet minutes close
  template → low, Datalake, no page
```

## Data Flow

```
batch lines → Grail → count per minute → > 0 → problem → standard flow
60 quiet minutes → close
```
