# Result

| Step | What to do |
|---|---|
| 1 | Run `8.sh` to confirm QA Platforms, its offering and the group exist |
| 2 | Upload `8-v5-default-qa-platforms-fallback.workflow.yaml` |
| 3 | To test the default set, edit SAMPLE_EVENT: remove the group tags and the host tag, then press Run |
| 4 | Check `snow_required.default_set_used` is true and `snow_form_check` has no MISSING rows |
| 5 | Put the tags back for normal testing |
