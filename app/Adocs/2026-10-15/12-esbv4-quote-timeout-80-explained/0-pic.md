# ESBv4 Quote Timeout 80 Pic

```
#80
 inner: "Timeout exceeded." lines → request IDs
 outer: "kakakucomauto/online/_quote" lines → request ID
 keep outer lines whose ID is in the inner list
 Splunk: subsearch + format (field named query = plain words)
 DQL: parse both sides + lookup + filter isNotNull(err.query)
```

```
Kakaku.com → esbv4 "Sending request" (ID) → pc quote → timeout → esbv4 "Timeout exceeded" (same ID)
```
