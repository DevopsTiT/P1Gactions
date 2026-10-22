# Confluence Show Table Lines

```
Table looks borderless / lines too faint?
 → Real Insert table (/table), not pasted plain text?
 → Publish / refresh view (edit mode can look different)
 → Cloud: borders are default; no strong “turn on lines” switch
 → Need darker lines? → header + cell colors, or DC/Server CSS / app
 → Legacy editor? → click table → Table options → borders
```

| Key point | Detail |
|---|---|
| Question | How to show table lines (borders) in Confluence |
| Cloud default | Normal tables already have light grey grid lines |
| Common miss | Content was pasted as text, or viewed only in a weird zoom/theme |
| Stronger look | Header row + cell background colors (Cloud has no border-color picker) |

## Summary

In **Confluence Cloud** (new editor), a real table already draws light grey lines. There is usually **no** toolbar button that says “Show borders.” If lines are missing, the block is often not a real table, or the lines are just very light. On **legacy / Server / Data Center**, table options or CSS can control borders more directly.

---

## Confluence Cloud (most common today)

### What “good” looks like

The Named Objects table on the page should look like a grid: header row slightly grey, thin lines between every cell. That **is** Confluence showing table lines — they are just light.

### Steps to get a real table with lines

| Step | Action |
|---|---|
| 1 | Edit the page |
| 2 | Put the cursor where the table should go |
| 3 | Type `/table` and choose **Table**, or use the toolbar **Table** button |
| 4 | Fill cells (header row on by default) |
| 5 | **Publish** or **Update**, then view the page (not only edit) |

Keyboard: Mac `Shift + Option + T` · Windows `Shift + Alt + T`.

### If lines still look missing

| Check | What it means | What to do |
|---|---|---|
| Pasted from Word / Excel / Markdown | Sometimes lands as messy or almost borderless content | Delete the block → insert a fresh `/table` → paste **cell values only** |
| Inside a code block | Monospace text, not a Confluence table | Remove the code fence; use Insert table |
| Only in Edit mode | Selection highlight can hide the feel of borders | Publish and open View |
| Theme / zoom / projector | Light grey borders wash out | Zoom to 100%; use header + cell colors below |

### Make the grid easier to see (Cloud workaround)

Cloud does **not** give a simple “border width / border color” control on normal tables. Practical tricks:

| Trick | How |
|---|---|
| Keep header row | Click table → table options / header toggle → **Header row** on |
| Color the header | Select header cells → cell background (e.g. light grey or light blue) |
| Color body rows | Select a row → light background so row edges read clearer |
| Avoid huge full-width washout | Resize table so columns are not ultra-wide empty space |

---

## Legacy editor (older Confluence UI)

| Step | Action |
|---|---|
| 1 | Edit page, click inside the table |
| 2 | Open the **Table** toolbar / **Table options** |
| 3 | Turn **borders** / gridlines **on** if the option exists |
| 4 | Save the page |

---

## Confluence Data Center / Server (admin CSS)

Admin stylesheet example (stronger lines):

```
table.confluenceTable td.confluenceTd,
table.confluenceTable th.confluenceTh {
  border: 1px solid #999 !important;
}
```

## Data flow map

```
Content intent (Object | Name)
  → /table insert
  → Confluence renders light grey cell borders (default)
  → Optional: header/cell color for stronger visual grid
  → Publish → readers see lined table
```

## Related files

| File | Role |
|---|---|
| [Atlassian tables doc](https://support.atlassian.com/confluence-cloud/docs/simplify-data-with-tables/) | Official Cloud help |
| `22.sh` | Dual-write |

## Commands

See [22.sh](22.sh).
