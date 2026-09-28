# Result

| Outcome | Detail |
| --- | --- |
| Workflow | 1-silva-post-mandatory-fields.workflow.yaml |
| Fills | All 9 mandatory fields + CI, contact type, company, impact, urgency, external ticket number |
| Guards | Throw if mandatory empty; verify after POST |
| Next | Run 1.sh, edit mapping blocks, add tags, test in STG |
