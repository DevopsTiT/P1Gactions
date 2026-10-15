# DQL Patterns Investigation

Grouped from the 85 DQL queries in answer 16 of 2026-10-15.

| Pattern | Queries |
|---|---|
| P1 text search | #2, #4 to #9, #11 to #13, #15, #16, #19, #29 to #31, #33 to #49, #51, #52, #54 to #59, #63, #64, #66 to #71, #73 to #75 |
| P2 keyword tagging | #1 |
| P3 parse | #22, #50, #60, #61, #65, #67 |
| P4 multi-line | #62 |
| P5 count and group | #3, #17, #20, #32, #41, #47, #53 chart |
| P6 freshness | #18, #76 |
| P7 lookup join | #72, #77 to #80 |
| P8 escaped JSON | #20, #23 to #28, #82 to #85 |
| P9 metrics | #21 |
| P10 lookup file | #81 |
| P11 platform | #14 |
| Not shown | #10 |

Some queries use two patterns. For example #20 is both P5 and P8, and #41 parses fields before counting.
