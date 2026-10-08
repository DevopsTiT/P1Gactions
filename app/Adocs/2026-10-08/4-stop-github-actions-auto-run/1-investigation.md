# Investigation

| What was checked | Finding |
|---|---|
| Actions screenshot | 278 runs; recent CI and Build and push runs failing on commits named "all" |
| `ci.yml` | Triggered on push and pull_request to main |
| `build-and-push.yml` | Triggered on push to main for `app/**` |
| Answer docs path | `app/Adocs/` matches `app/**` |
