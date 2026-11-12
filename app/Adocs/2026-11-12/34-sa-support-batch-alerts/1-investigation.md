# Investigation

Index sa-support-batches on all three. Throttle is off. Email priority is Normal. Expires is 24 hours. There is no PagerDuty action.

Sa Support Batch Error searches the word error. Last 6 minutes. Every 5 minutes. Count greater than 0, once.

Sa Support Batch File Import Confirmation searches three phrases with OR: importFileHandler :: runner :, importSagaFundGroup, and started. Last 24 hours. Cron 30 8 * * 1-5, which is 08:30 Monday through Friday. Count is less than 2, once. To is axa.jp_di_bap_annuitypayments@axa.co.jp. The line wraps after the @.

Sa Support Batch Task Time Out searches Task timed out. Last 6 minutes. Every 5 minutes. Count greater than 0, once.

The error form and the timeout form share a To box. The visible text is alj_jp_di_bap_commonins@ound2@axa.co.jp and maki.kawauchi.ose@axa.co.jp. The first value has two @ signs. Confirm both.
