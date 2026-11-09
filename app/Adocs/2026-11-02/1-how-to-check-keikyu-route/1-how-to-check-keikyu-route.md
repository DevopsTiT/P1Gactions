# How To Check This Route

```
Want the ride from 六乡土手 to 泉岳寺
  open a route search
    type 六郷土手 → 泉岳寺
    read: time, transfers, fare, train type
  at 六乡土手, read the departure board
    普通 品川 → board
    普通 羽田空港 → leave it
  at 京急蒲田, read the next board
    品川 / 泉岳寺 / 押上 → board
  fare
    ticket machine, choose 泉岳寺
    the price on the screen is the fare
```

| Fact | Where it comes from |
|---|---|
| Only local trains stop at 六乡土手 | The Keikyu station page, and the departure board. |
| Do not take the Haneda train | The board says 羽田空港. That train leaves the main line at 京急蒲田. |
| Change at 京急蒲田 | A route search such as 駅探 or Google Maps. |
| About 20 minutes and 280 yen | One 駅探 result on 2026-10-08. The ticket machine is the fare for today. |
| Get off at 泉岳寺 | The in-train display and the platform signs. |

## Summary

You do not need to remember the route. Type the two station names into a route search, then match the train type on the station board. The board at 六乡土手 shows 品川 or 羽田空港. Take 品川. The ticket machine shows the fare when you select 泉岳寺.

## Investigation

| Source | What it showed |
|---|---|
| Keikyu station page for 六郷土手 | Station number KK19. Toward 泉岳寺, the listed trains are locals to 品川 or to Haneda Airport. |
| 駅探 on 2026-10-08 | One sample: local to 京急蒲田, then a limited express, arrive 泉岳寺 in 20 minutes. Ticket price shown as 280 yen. |
| Keikyu timetable note | The posted weekday times were from the 2025-12-13 revision. The platform display is the one that applies on the day you travel. |

## Result

Use three checks. Each one answers a different question.

| Question | What you open | What you read |
|---|---|---|
| Which train, where to change, how long | 駅探, Yahoo 乗換, or Google Maps | From 六郷土手 to 泉岳寺. Note the train type and the change station. |
| Is this the train in front of me | The board above the platform | 普通 and 品川. Skip a train marked 羽田空港. |
| What does it cost today | The Keikyu ticket machine | Select 泉岳寺. Pay the amount on the screen. An IC card charges the same ride when you tap out. |

At 京急蒲田, use the board again. Board a train whose direction includes 品川, 泉岳寺, or 押上. Stay on it until the display says 泉岳寺.

The 20 minutes, the 280 yen, and a clock time such as 19:50 are examples from a published search and a posted timetable. They are not a promise for this evening. The search box and the platform board are the check.

## Data flow map

```
Type 六郷土手 → 泉岳寺
        |
        v
Route result
  train type, change station, minutes, sample fare
        |
        v
Platform board at 六乡土手
  品川 → ride
  羽田空港 → wait
        |
        v
京急蒲田 board
  品川 / 泉岳寺 / 押上 → ride
        |
        v
In-train display says 泉岳寺 → get off
        |
        v
Ticket machine or IC tap
  fare for this ride
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | What to check, in order. |
| `1-investigation.md` | Where the earlier route facts came from. |
| `2-result.md` | The three checks. |
| `3-glossary.md` | The words on the board. |
| `1-how-to-check-keikyu-route-follow.txt` | The same steps for a phone. |
| `1.sh` | Copy commands. |

Commands: [1.sh](1.sh)
