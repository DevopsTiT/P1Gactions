# AG Portal NTTGW Glossary

| Term | What it means | Why you care |
|---|---|---|
| build_report | A Jenkins event sent after each build, with results and test cases | The data this alert reads |
| Real Time Check | A frequent App-Ops job that checks the app is up | Its result decides OK or NG |
| Functional job | An App-Ops job that runs feature tests | Counted, but not judged here |
| UNSTABLE | Jenkins result when the build ran but some tests failed | The main way to reach NG, since FAILURE is excluded |
| configuration lookup | A table mapping Jenkins job names to applications | Wrong spelling means no matches |
