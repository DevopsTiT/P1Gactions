# Terraform Variables Inside Resource Pic

```
variable / locals inside resource {}  → NO (validate error)
variable / locals at top of same file → OK (Option A)
no variable / locals, literal values  → OK (Option B, matches team style)
same names in another .tf in folder   → Duplicate error → rename
placeholder email                     → replace before apply
```
