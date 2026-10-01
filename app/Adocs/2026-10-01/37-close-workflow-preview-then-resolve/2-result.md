# Result

| Step | Action |
|---|---|
| 1 | Run `37.sh` lines 1 and 2 to see the real state and close_code values. |
| 2 | Import `37-close-workflow-preview-then-resolve.workflow.yaml`. |
| 3 | Press Run: sample close of P-261090. Check both previews. Send tasks skip. |
| 4 | Fix CLOSE_CODE if the preview says WRONG. |
| 5 | To really close P-261090: ALLOW_SAMPLE_POST = true in both send tasks, Run. |
| 6 | Run `37.sh` line 3 to confirm Resolved. |
| 7 | Save / Deploy so real problem closes trigger it. |
