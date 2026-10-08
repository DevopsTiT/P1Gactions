# HPM Owner Portal NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| jenkins/test | Splunk source for Jenkins build reports | All four alerts read it |
| build_report | event_tag on each finished build | Used as the first filter |
| App-Ops Functional job | Detailed test job | Not counted for OK/NG |
| App-Ops Real Time Check | Frequent health job | Renamed to its Functional project, counted |
| applications/* job | Plain per-app check job | Counted; the earlier detectors missed these |
| In-place update | Terraform changes an existing resource without recreating it | Same resource names keep problem history |
