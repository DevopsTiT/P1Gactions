# Splunk Internal Mailservice Hosts Pic

## Decision tree

```
#14 license usage → Splunk-only → log text size per day
#15 / #16 mailservice → no index in Dynatrace → host / namespace / bucket filter
  0 rows? → mailservice check query → still 0? → onboarding request
#17 throughput → Splunk-only → lines per minute per source, top 5
#18 silent hosts → last log time per host → silent > 1 hour
```

## Data flow

```
#14 Grail -> size per line -> sum per day
#15 Grail -> mailservice -> AuthenticationFailedException
#16 Grail -> mailservice -> Catalina.start Server startup
#17 Grail -> count per minute per source -> top 5
#18 Grail -> prod hosts -> last log -> > 3600 s -> behind columns
```
