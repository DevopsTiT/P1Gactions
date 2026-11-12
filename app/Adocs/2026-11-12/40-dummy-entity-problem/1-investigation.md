# Investigation

The dev Lambda error metric is flat in the recent window, so a short alert cannot fire. dt.entity.custom_device is empty on that metric.

dt.host.cpu.usage is present for monitored hosts. Grouping by dt.entity.host supplies the id that dt.source_entity can copy.
