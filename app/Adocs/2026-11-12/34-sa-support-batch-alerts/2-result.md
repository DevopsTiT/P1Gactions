# Result

ALJ_SABATCH covers the error and the timeout. ALJ_ANNUITY covers the file-import check because that form mails a different address.

The file-import detector fires when the count is less than 2. A wrong index field makes that count stay at 0, so the alert would fire all the time.

pagerduty.enabled is 0. Event severity is medium. Profile severity level is ERROR.
