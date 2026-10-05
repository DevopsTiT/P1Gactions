# Investigation

| What was checked | Finding |
|---|---|
| Screenshots 1 and 2 | `eopt-serverless.tf`, same as the seq 11 check |
| Alert 1 | parseNdAndUpdateDb, ND_SEARCH_RESULT_FILE, counts searchResult, noContract, contractExists |
| Alert 2 | buildAnswerFile, ANSWER_FILE, counts requestingGovernment, answer, noMatch, contractExists, electronicAnswerUnavailable |
| Alert 3 | validateAndComputeAnswer, REQUEST_FILE, counts requestingGovernment, contractRequest, precheckResult |
| Alert 4 | logFailure, level:ERROR |
| Alert 5 | parseErrorFileAndUpdateDb, ParseErrorFileAndUpdateDB (error file from pipitLINQ) |
| Alert 6 | parseSysErrorFileAndUpdateDb, parseGatewaySysErrorFileAndUpdateDbEffect (system error file from Kyoto GW) |
| Alert 7 | parseMdmResponseAndUpdateDb, Biz file summary |
| Common | Every 5 minutes, more than 0, email to digitalservices maintenance |
| Secrets | None |
