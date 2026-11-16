# Investigation

Splunk has 992 events. Each source has 496: `eip_mg_up_check://EIP UP Check WPALJA21B9` and `eip_mg_up_check://EIP UP Check WPALJA21BC`.

The opened event body is an `MG_Result` object. The DQL filter required those source words inside Dynatrace `log.source`, over the last 3 minutes.
