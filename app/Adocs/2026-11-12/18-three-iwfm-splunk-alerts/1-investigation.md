# Investigation

EIP006: index eip1015, sourcetype eip_mediator_serverlog, service jp-Distributing-Sell-GenerateFormImage-v2-vs, Status FAILURE. Last 1 minute. Greater than 2, once. Mail alj_jp_di_infra_mwss@axa.co.jp. Priority High.

Compass: index compass-prod-axa-11-jp, text IWFMReportException. Last 5 minutes. Greater than 15, once. Mail axa.jp_di_compass_it_member@axa.co.jp. A second To line is cut off. Expires 1500 days. Priority Normal.

iWFM Errors: index iwfm, sourcetype fmwagentlog, LOGLEVEL Caution or Fatal, earliest -1h, then transaction. Greater than 0, once. Throttle 1 hour. Run at minute 15. Mail rajukolukuluri@axa.co.jp. Priority Normal.
