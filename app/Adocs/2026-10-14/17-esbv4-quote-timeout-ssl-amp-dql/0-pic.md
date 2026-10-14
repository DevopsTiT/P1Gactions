# ESBv4 Quote Timeout, SSL, AMP Pic

## Decision tree

```
#78–#80 → lookup timeout IDs → channel request lines
#81 → lookup file? load : Synthetic cert check
#82–#85 → JSON parse → url / type / level
```

## Data flow

```
timeout errors -> IDs -> request lines per channel
cert end date -> < now + 30d
amp-backend JSON -> filter -> list
```
