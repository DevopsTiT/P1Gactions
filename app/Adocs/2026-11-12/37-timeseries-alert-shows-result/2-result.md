# Result

Remove the custom device from the query. Sum the metric by the log group only. When a line shows, put the real CUSTOM_DEVICE id in dt.source_entity on the event template.

Do not add isNotNull(dt.smartscape_source.id) until a query that includes that field still returns a line.
