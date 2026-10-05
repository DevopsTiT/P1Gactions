# WeChat Photo Files Mac Location

## Decision tree

```
Where are the File Transfer photos on the Mac?
 already pasted into Cursor?    → yes → ~/.cursor/projects/Users-k-Codes/assets/*.png (normal PNG, easiest)
 need them straight from WeChat?
   easiest                      → in WeChat select the photos → right-click → Save As / Save to Downloads
   raw WeChat cache (4.x)       → ~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/<account>/msg/attach/<chat-hash>/<YYYY-MM>/Img/
     files end in .dat          → encrypted cache, not normal JPG, cannot open directly
```

## Short takeaway

| Question | Answer |
|---|---|
| Fastest place to find them | `~/.cursor/projects/Users-k-Codes/assets/` (Cursor saved a PNG copy of every photo you pasted into chat) |
| WeChat's own folder | `~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/Kimi_113_423e/msg/attach/` |
| Can I open WeChat's copies? | Usually no. WeChat 4.x stores images as encrypted `.dat` files |
| Best way to get real JPGs from WeChat | Select photos in File Transfer, right-click, Save As |

## Summary

The photos you sent to Cursor are already saved as normal PNG files in the Cursor assets folder. WeChat keeps its own copy inside its sandbox folder, but as encrypted `.dat` cache files, so saving from the WeChat app is the reliable way to get JPGs.

## Locations

| Location | Path | File type |
|---|---|---|
| Cursor copies | `/Users/k/.cursor/projects/Users-k-Codes/assets/` | PNG, named like `<hash>-<uuid>.png` |
| WeChat 4.x cache | `/Users/k/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/Kimi_113_423e/msg/attach/<chat-hash>/2026-10/Img/` | Encrypted `.dat` |
| WeChat 3.x (older app) | `~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/<version>/<hash>/Message/MessageTemp/<chat-hash>/Image/` | Encrypted `.dat` |

## Save from WeChat (real JPGs)

| Step | Action |
|---|---|
| 1 | Open File Transfer in WeChat |
| 2 | Right-click a photo and choose Multi-select, tick all photos |
| 3 | Click the save (download) icon and choose a folder, for example `~/Downloads/splunk-alerts` |

## Data flow

```
phone camera → WeChat File Transfer → Mac WeChat cache (.dat, encrypted)
                                    → Save As → Downloads (JPG)
                                    → paste into Cursor → assets/*.png
```

## Investigation

| Checked | Found |
|---|---|
| WeChat container | Account folder `Kimi_113_423e` exists with `msg/attach/<hash>` |
| Listing image files inside | Blocked by macOS privacy protection for the WeChat container |
| Cursor assets folder | Holds the PNGs of every pasted screenshot today |

## Result

Use the Cursor assets folder for the photos you already pasted. For new ones, save from WeChat with Multi-select, then Save.

## Related files

| File | Purpose |
|---|---|
| `33.sh` | Commands to open the folders |

## Commands

See `33.sh`. Not run.

```
open ~/.cursor/projects/Users-k-Codes/assets
open ~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/Kimi_113_423e/msg/attach
ls -lt ~/.cursor/projects/Users-k-Codes/assets
```
