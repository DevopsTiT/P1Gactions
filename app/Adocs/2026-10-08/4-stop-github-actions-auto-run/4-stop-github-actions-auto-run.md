# Stop GitHub Actions Auto Run

## Decision tree

```
Every push to P1Gactions starts workflows (and they fail)
 Which workflows?
  CI              → on push to main + pull_request → runs on every commit
  Build and push  → on push to main, paths app/** → app/Adocs/** matches → runs on every doc push
 Want them to run at all?
  no, never automatically → trigger = workflow_dispatch only → DONE (this change)
  only for code, not docs → keep push, add paths-ignore: app/Adocs/** (alternative)
  pause without editing   → GitHub > Actions > workflow > ... > Disable workflow
 Change takes effect after the edited yml files are pushed to main
```

## Short takeaway

| Question | Answer |
|---|---|
| Why did workflows run? | Both trigger on push to main. Adocs lives under `app/`, which Build and push watches. |
| What changed? | Both workflows now use only `workflow_dispatch` (manual run button). |
| Will a push still run them? | No, once these yml changes are on main. |
| Can I still run them? | Yes. Actions tab, pick the workflow, click Run workflow. |
| Pushed for me? | No. You commit and push (commands in `4.sh`). |

## Summary

`ci.yml` ran on every push and pull request, and `build-and-push.yml` ran on any change under `app/**`, which includes the `app/Adocs/` answer folders. Both now only run when someone clicks Run workflow in GitHub.

## What changed

| File | Before | After |
|---|---|---|
| `.github/workflows/ci.yml` | `push` to main and `pull_request` to main | `workflow_dispatch` only |
| `.github/workflows/ci.yml` (deploy job) | `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` | `if: github.ref == 'refs/heads/main'` so a manual run on main still deploys |
| `.github/workflows/build-and-push.yml` | `push` to main on `app/**` | `workflow_dispatch` only |

New trigger in both files:

```yaml
on:
  workflow_dispatch:
```

## Other options

| Option | When to choose it | How |
|---|---|---|
| Manual only | You never want automatic runs | This change |
| Ignore docs only | You still want CI for real code changes | Keep `push` and add `paths-ignore: ["app/Adocs/**"]` |
| Disable in the UI | Quick pause without a commit | Actions, workflow, three dots, Disable workflow |
| Skip one commit | One-off push | Put `[skip ci]` in the commit message |

## Data flow

```
Before: git push → GitHub → CI + Build and push start → fail → red X
After:  git push → GitHub → no workflow starts
        Actions tab → Run workflow (manual) → workflow runs
```

## Investigation

| What was checked | Finding |
|---|---|
| Screenshot | Many runs titled "all", recent ones failing, both CI and Build and push |
| `ci.yml` trigger | push and pull_request on main |
| `build-and-push.yml` trigger | push on main, paths `app/**` |
| Adocs location | `app/Adocs/`, inside the watched path |

## Result

| Step | What to do |
|---|---|
| 1 | Review the two yml edits |
| 2 | Commit and push them (see `4.sh`). This push itself will not start the workflows. |
| 3 | Check the Actions tab: no new runs after later pushes |

## Related files

| File | Purpose |
|---|---|
| `P1Gactions/.github/workflows/ci.yml` | CI, now manual |
| `P1Gactions/.github/workflows/build-and-push.yml` | Image build, now manual |
| `4.sh` | Commands |

## Commands

See `4.sh`. Not run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git diff .github/workflows
git add .github/workflows/ci.yml .github/workflows/build-and-push.yml
git commit -m "Run GitHub Actions workflows manually only"
git push
```
