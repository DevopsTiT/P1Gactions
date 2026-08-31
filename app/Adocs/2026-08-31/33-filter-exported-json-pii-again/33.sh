python3 "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/33-filter-exported-json-pii-again/33-filter-dt-json-pii.py" ~/Downloads/dt-pii-export.json ~/Downloads/dt-pii-filtered.json
python3 "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/33-filter-exported-json-pii-again/33-filter-dt-json-pii.py" ~/Downloads/dt-pii-export.json ~/Downloads/dt-pii-redacted.json --redact
jq '[ .[] | select( (.content // "") | test("address, Value =|AddressKana|person_fullname|phoneNumber, Value =|住所|電話番号"; "i") ) | select( (.content // "") | test("CleansingResult|cleansingResult") | not ) ]' ~/Downloads/dt-pii-export.json > ~/Downloads/dt-pii-filtered.json
jq '[ .records[]? // .data[]? // .[] | select( (.content // "") | test("address, Value =|AddressKana|person_fullname|phoneNumber, Value =|住所|電話番号"; "i") ) | select( (.content // "") | test("CleansingResult|cleansingResult") | not ) ]' ~/Downloads/dt-pii-export.json > ~/Downloads/dt-pii-filtered.json
# git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add app/Adocs/2026-08-31/33-filter-exported-json-pii-again
# git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: second-pass filter Dynatrace JSON export for real PII"
# git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
