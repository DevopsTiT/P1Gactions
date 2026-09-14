echo "SNOW URL: copy https://INSTANCE.service-now.com from browser"
echo "SNOW user/pass: ask admin for integration account"
echo "sys_id: open record URL, copy value after sys_id="
echo "PD key: Service → Integrations → Events API v2 → Integration Key"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/23-how-to-get-placeholder-values"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: how to get SNOW PD workflow placeholder values"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
