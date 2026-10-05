# Glossary

| Term | What it means |
|---|---|
| Top-level block | A block written directly in a `.tf` file, not nested in another block |
| `variable` | An input value for the module, used as `var.name` |
| `locals` | Named values computed inside the module, used as `local.name` |
| Module | All `.tf` files in one folder, read together as one unit |
| Heredoc | Multi-line string between `<<-EOT` and `EOT` |
| Interpolation | `${...}` inside a string, replaced with a value at plan time |
