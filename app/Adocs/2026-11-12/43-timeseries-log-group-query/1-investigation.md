# Investigation

The Timeseries query groups log.lambda_errors by aws.log_group and dt.entity.custom_device, then keeps only rows where the custom device is not null. That device field is empty, so the box has no line.

The same metric grouped only by aws.log_group already returned a chart. The screen asks for dt.smartscape_source.id to connect an entity.
