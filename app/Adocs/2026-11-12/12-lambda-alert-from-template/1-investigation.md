# Investigation

The detector resource is `for_the_happy_future_error_front_end_pod`. It uses the record analyzer, `from: now()-5m`, and `event.type` `CUSTOM_ALERT`. The profile `ALJ_OCP4_alerting_profile` requires severity level `ERROR` and a title that begins with `ALJ_OCP4`. The email resource points at that profile. The open Edit alert form has no completed condition section.
