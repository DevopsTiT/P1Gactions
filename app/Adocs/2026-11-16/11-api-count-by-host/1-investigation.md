# Investigation

The panel counts `eip_mediator_serverlog` events by `API` and by `host`. It copies each event onto a placeholder host `----`, charts that copy, and renames the placeholder column to `ALL`. `index=* OR index=_*` does not add logs beyond `index=eip1015`. The time range is the shared picker. Refresh is every 2 minutes.
