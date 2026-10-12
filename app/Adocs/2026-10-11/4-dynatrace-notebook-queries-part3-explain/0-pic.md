# Dynatrace Notebook Queries Part 3 Pic

```
G  service → host name     → works; null host = external or remote service
H  services on ADJ hosts    → 134 rows, complete; filter after expand for exact hosts
I  CPU where tag == Windows → 0 records; use osType == "WINDOWS"
J  tags across entity types → exact tag match fails; check tags, use contains()
```

```
tag(ADJ) → classicEntitySelector → host IDs → services (H)
cpu metric → by host → osType / tags → filter (I)
host + service + process + cloud → append → expand tags → filter (J)
```
