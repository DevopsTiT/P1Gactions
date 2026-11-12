# Investigation

Both searches use index recruitimp-serverless. Both fire when the count is greater than 0, once. Throttle is off. Email priority is Normal. Expires is 24 hours. There is no PagerDuty action.

RI Monitoring Error looks at the last 5 minutes and runs every 5 minutes. It keeps the word after a tab when that word is ERROR. The To line is alj_jp_di_etool_maintenance@axa.co.jp.

recruitimp AWS Serverless Error has no time range. It runs every day at 8:00. It uppercases the text after level: and keeps ERROR. The To lines are alj_jp_di_etool_maintenance@axa.co.jp and chungyueh.chiu@axa.co.jp.
