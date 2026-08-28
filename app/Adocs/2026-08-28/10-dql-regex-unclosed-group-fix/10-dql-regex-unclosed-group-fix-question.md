# User question (verbatim)

User shared screenshot of Dynatrace DQL error when searching PII keywords.

**Error:** `'Unclosed group' at position 1249` in regex ending with `lastName")`

**Root cause:** typo — extra `"` before closing paren: `lastName")` should be `lastName)` inside the `matchesRegex` string.

The query filters host group `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` and has a huge `matchesRegex` with many insurance/AXA field names.

## Deliverable requested

1. Explain the error in plain English (beginner SRE)
2. Provide corrected full DQL query with fixed regex (dedupe repeated keys: mail, holderName, given_name, family_name, bankName)
3. If regex too long for Dynatrace, provide split strategy (Options A/B/C)
4. Categorize all fields: names, addresses, phone, email, bank, IDs, DOB, gender
5. Sample query with limit 10
6. Link to seq 7/9 prior work

Builds on seq 7 (insurance PII keywords) and seq 9 (expanded host inventory patterns).
