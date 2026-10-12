# Process Network Charts Investigation

| Cell | Evidence on screen |
|---|---|
| Y | network.load, PROCESS_GROUP_INSTANCE-8C3B..., 6/28 to 7/1, spiky |
| Z | bytes_rx, m1[]*8, label Bytes received, 2 hours, spikes to about 1.2 Mbit/s |
| AA | bytes_rx by instance, filter process_group PROCESS_GROUP-A73B79EBAEDBF111, 2 records |
| BB | by process_group, filter process_group == PROCESS_GROUP_INSTANCE-B205..., 0 records |
| CC | network.load, PROCESS_GROUP_INSTANCE-3A9B..., mostly zero with bursts |
