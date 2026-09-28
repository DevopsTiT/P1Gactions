# Result

| Order | Action |
|---|---|
| 1 | Get the EIP L2 group and offering from Abhay; verify ALJ_EIP_PRD in SILVA. |
| 2 | Fill SYSTEM_MAP in OPEN and CLOSE; add COMPASSPROXY once known. |
| 3 | Replace the three placeholders or set them to "". |
| 4 | Apply the duplicate fix (drop UPDATED, or add the correlation_id check). |
| 5 | Set SEND_CONFIGURATION_ITEM = false. |
| 6 | Import, allowlist, run OPEN and CLOSE tests, and read the result fields. |
| 7 | Before go-live, empty ASSIGNED_TO and relax the fixed test values. |
