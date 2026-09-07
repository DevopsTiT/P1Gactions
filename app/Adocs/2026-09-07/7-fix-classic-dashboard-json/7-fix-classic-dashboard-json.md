# Fix Classic Dashboard JSON Errors

Your Dynatrace Classic editor reported:

1. `tiles[5].assignedEntities` must not be null → **DATABASE** tile needs `"assignedEntities": []`
2. HEADER `LOGS — wrong / bad logs` top `1502` invalid → **top/left/width/height must be divisible by 38**

## Fixed file

`App-Must-Should-Watch-Classic.json` (this folder + updated copies)

## Re-import

1. Replace dashboard JSON with the fixed file (or paste into Edit JSON)
2. Save changes
3. Database tile may still say pick a DB until you assign one — empty array is valid for save; pick entity in UI if needed
