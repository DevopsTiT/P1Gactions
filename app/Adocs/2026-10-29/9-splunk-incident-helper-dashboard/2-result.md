# Result

Create a Dashboard Studio grid. Add a time input named Search by Time, default Last 15 minutes, with auto-refresh. Each box is one search.

A count uses Single value and `stats count`. ND Mode uses Single value and `stats latest(...)`. A server list uses Table and `stats latest(status) by host`.

Paint failure panels red and success panels green, including when the value is 0.

Replace `YOUR_INDEX` and `YOUR_SOURCE` with the values from the existing panel. Open a panel and choose Open in search to copy the real SPL.

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE FAILURE
| stats count
```

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE (WPLALJ2CO OR WPLALJ2BF) FAILURE
| stats count
```

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE
| stats latest(nd_mode) AS mode
```

```
index=YOUR_INDEX sourcetype=YOUR_SOURCE (host="WPLALJ2BF.axajp.intraxa" OR host="WPLALJ2CO.axajp.intraxa")
| stats latest(MS_ResultMS_Status) AS MS_ResultMS_Status by host
```

No results found means that search matched zero events in the last 15 minutes. Open it, widen the time, and compare the host filter with the panel that has rows.
