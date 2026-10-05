# HTTP Response Outlier Investigation

| Screenshots | Alert | Finding |
|---|---|---|
| 1 and 2 | Application Monitoring Alert - URL | Same as seq 34 |
| 3 and 4 | Application Monitoring Alert - URL for MyAXA | Same as seq 34 |
| 5 to 7 | Application Monitoring Alert - function | Same as seq 34 |
| 8 and 9 | HTTP Response Check Outlier | Median and MAD outlier on AGGW LB, Last 24 hours, every 10 minutes, email masayuki.yasuda, subject 【TEST】 |

| Observation | Meaning |
|---|---|
| 20 x MAD band | Very wide; may rarely fire |
| Test subject | Probably not production |
| Lower bound included | Fast responses also flagged; dropped in Dynatrace |
