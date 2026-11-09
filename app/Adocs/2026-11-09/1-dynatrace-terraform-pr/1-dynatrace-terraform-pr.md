# Dynatrace Terraform Pull Request

```
Create a pull request in aljdevops/dynatrace-terraform
  this machine
    gh is not installed
    git ls-remote to github.axa.com waited for a login
    no local copy of the repository
  the photo
    repository home and the Code menu
    no edited file
  result
    no branch, no commit, no pull request
```

| Check | Result |
|---|---|
| Repository | https://github.axa.com/aljdevops/dynatrace-terraform |
| GitHub CLI | `gh` is not installed. |
| Login | `git ls-remote` waited for a login and was stopped. |
| Local copy | None under `/Users/k/Codes`. |
| Change in the photo | The Code menu is open. No file diff is shown. |

## Summary

The pull request was not created. The repository address is `aljdevops/dynatrace-terraform` on `github.axa.com`. This machine has no GitHub CLI and did not get past the login prompt. The photo shows the repository home page, so there is no file change to commit.

## Investigation

| Source | Finding |
|---|---|
| Browser address | `https://github.axa.com/aljdevops/dynatrace-terraform` |
| Code menu | HTTPS clone starts with `https://github.axa.com/aljdevops/dynatrace-terr` |
| Branch on screen | `main`. 17 branches. 6 pull requests already exist. |
| Local disk | No `dynatrace-terraform` directory. |
| Commands run | `gh` was missing. `git ls-remote` did not return a commit. |

## Result

A pull request needs a signed-in copy of the repository and one committed change. Both are missing here.

After you are logged in to `github.axa.com` in the browser or in Git, these are the commands. Run them yourself. The last three create the branch, upload it, and open the pull request. Replace the commit message with the change you actually made.

```
git clone https://github.axa.com/aljdevops/dynatrace-terraform.git
cd dynatrace-terraform
git checkout -b add-the-change
git add .
git commit -m "Describe the change."
git push -u origin HEAD
```

`gh` is not on this Mac, so the website is the way to open the pull request. After the push, GitHub shows a button on the repository page: Compare and pull request.

The log-path note from earlier is a different decision. The custom source block in that photo was cut off, and the four checks were not confirmed. That note is not this pull request.

## Data flow map

```
Photo
  github.axa.com/aljdevops/dynatrace-terraform
        |
        v
this machine
  no gh
  login did not complete
  no local files
        |
        v
no pull request
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Why the pull request stopped. |
| `1-investigation.md` | What the photo and this machine showed. |
| `2-result.md` | The commands to run after login. |
| `3-glossary.md` | The words. |
| `1-dynatrace-terraform-pr-follow.txt` | The same steps for a phone. |
| `1.sh` | The commands. |

Commands: [1.sh](1.sh)
