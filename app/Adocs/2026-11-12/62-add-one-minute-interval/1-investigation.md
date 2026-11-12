# Investigation

The open form uses the host CPU query for `HOST-00026D8D201D203A` and groups by `dt.entity.host`. The query does not set `interval:1m`. Query offset is empty.

Add details still includes `dt.smartscape_source.id` = `{dt.smartscape_source.id}`. `dt.source_entity` is `{dt.entity.host}`. Title and event name are `TESTDUMMY host entity`. `event.type` is `CUSTOM_ALERT`.

A notebook run of this host query returned one record and the line stayed under 20. Davis static threshold counts one-minute samples. The alert query has to set that interval itself.
