# Dynatrace Control-M Pic

```
Need abend?     → daily_ctmag / alert logs → DQL detector (seq 39)
Need overrun?   → STARTED vs ENDED by ORDERID → DQL detector (seq 40/41)
Need live status? → Hub Control-M Jobs v2 → ActiveGate → Automation API
Need EM health? → OneAgent on EM/Server/Agent (never 1.327 on EM Linux until BMC fix)
```
