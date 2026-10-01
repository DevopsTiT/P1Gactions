# Result

| Step | Do |
|---|---|
| 1 | Run V1; copy each `element` next to its label |
| 2 | If V1 is empty or 403, run V3 and see which guessed keys come back |
| 3 | For a missing key, run V4 with `column_labelLIKE<word>` to find the real name |
| 4 | Run V5 to get valid values for choice fields |
| 5 | Update the seq 10 table and the payload keys with confirmed names |
