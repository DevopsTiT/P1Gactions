# Investigation

log.lambda_errors has no dt.entity.custom_device and no dt.entity.host dimension. Grouping by either one removes the line. The host id from the CPU list can be added with fieldsAdd after the metric query.
