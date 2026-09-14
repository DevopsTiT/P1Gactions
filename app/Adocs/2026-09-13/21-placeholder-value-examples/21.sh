echo "Examples are FAKE — replace with real SNOW/PD values"
echo "__SNOW_INSTANCE_URL__ example: https://acme.service-now.com"
echo "__PD_ROUTING_KEY__ example: 32-char integration key from PD"
echo "sys_id examples: 32 hex chars from SNOW record URL"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/21-placeholder-value-examples"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: example values for SNOW PD workflow placeholders"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
