# CHDE010M MyAXA UL Pic

```
Splunk: 11:30 Mon-Sat → mail yesterday's CHDE010M status (OK or 要確認)
Dynatrace: problem only for 要確認
 yesterday's odate (yyMMdd) → latest status
 Mon-Sat and JST >= 11:30 → not Ended OK → problem (medium, pd 0)
 rerun OK or midnight → closes
 remove 10-07 seq 14 chde010m_no_success if applied
```
