# Cron And Expires Picture

## Decision Tree

```
0 8 * * *   → when it runs → 08:00 daily (server time zone)
Today       → what it reads → 00:00 to run time
Expires 24h → how long the fired result is kept → then deleted
Dynatrace detector → no cron, no expires
Dynatrace workflow → cron + Asia/Tokyo
```

## Data Flow

```
08:00 → search Today → results > 0 → email → kept 24 h → deleted
```
