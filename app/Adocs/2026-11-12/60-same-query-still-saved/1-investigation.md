# Investigation

The new screenshot is the same Edit alert form. The query box still starts with `timeseries errors = sum(log.lambda_errors)` for `/aws/lambda/gov-inquiry-system-dev-logFailure`, then `fieldsAdd dt.entity.host`.

Source is Alert management. Define alert condition is completed. Actor is shuge kui.

That query returned 0 records on Last 2 hours. The host CPU query returned 1 record and the line stayed under 20.
