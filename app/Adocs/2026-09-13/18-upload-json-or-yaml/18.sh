echo "Recommend: upload two YAML templates (create + close)"
echo "ago-problem-to-snow-pagerduty.workflow-template.yaml"
echo "ago-problem-closed-resolve-snow-pd.workflow-template.yaml"
echo "Do not also upload the JSON twins for the same workflows"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/18-upload-json-or-yaml"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: recommend YAML upload for SNOW PD workflows"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
