# Investigation

Index pmt-api. Greater than 0, once. Last 5 minutes, except Task timed out which is last 6 minutes. Cron is every 5 minutes. Expires 24 hours. Email priority is Normal. No PagerDuty action.

SFDC mails ALJ_JP_DI_operations@axa.co.jp and TS_JP_DI_applications@axa.co.jp. The box is small. Confirm both.

Process automation is alj_jp_di_processautomation@axa.co.jp. That mailbox is on unexpected error, transformation timeout, SendApprovalReminder, the visible mail-sender form, and the email-sending error.

koichi.nagamine@axa.co.jp is also on memory over 480 and ExportData. Confirm that spelling.

The Emma-named mail-sender form has Triggered Alerts at Medium and a collapsed Send email action. No address was visible.

Throttle is 60 seconds on the approval reminder, both mail-sender alerts, ExportData, and the email-sending error.

The five onboarding-batch screens in the same batch were already converted. They are not in this file.
