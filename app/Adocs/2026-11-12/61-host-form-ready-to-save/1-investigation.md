# Investigation

The form now has the host CPU query for `HOST-00026D8D201D203A`, grouped by `dt.entity.host`.

The condition is static threshold, below 101. Alert on missing data is on. Violating samples is 3. Sliding window is 5. Dealerting samples is 5. The Edit alert dialog is still open.

Title and event name are `TESTDUMMY host entity`. `event.type` is `CUSTOM_ALERT`. `dt.source_entity` is `{dt.entity.host}`. A second property still sets `dt.smartscape_source.id` to `{dt.smartscape_source.id}`. The query does not return that column.

The same host query returned 1 record earlier. The line stayed under 20.
