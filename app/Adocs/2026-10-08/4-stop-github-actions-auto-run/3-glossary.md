# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Workflow | A YAML file in `.github/workflows/` that GitHub runs | CI and Build and push are workflows |
| Trigger (`on:`) | The event that starts a workflow | Changing it stops automatic runs |
| `push` trigger | Runs on every git push | Why every doc push started runs |
| `paths` filter | Only run when these files change | `app/**` included the Adocs folder |
| `workflow_dispatch` | Manual trigger with a Run workflow button | Lets you run on demand only |
| `paths-ignore` | Skip runs when only these files change | Alternative if you want CI for code only |
| `[skip ci]` | Commit message tag that skips workflows for that push | One-off skip |
