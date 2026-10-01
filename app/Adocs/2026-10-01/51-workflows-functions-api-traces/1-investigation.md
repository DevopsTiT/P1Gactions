# Investigation

| What I checked | Finding |
|---|---|
| OPEN functions | Task 1: 9, task 2: 15 (incl. fromMap, envMatch), 4a: 2, 5a: 2, tasks 3, 4b, 5b: main only. |
| CLOSE functions | Task 1: 4, 2a: 9 (incl. stateBody, isResolved, main), 2b: main only. |
| Network calls | Only getProblem, getRows, patch, and the direct fetch calls in 4a, 5a, 5b, 2b. |
| Built-in traces | OPEN task 2 `steps`, CLOSE 2a `attempts`. |
| Trace order in section 4 | Derived from the code; the real order per run is in `steps`. |
