import csv
import re
import sys
from collections import defaultdict

in_path = sys.argv[1] if len(sys.argv) > 1 else "silva_offerings_env.csv"
long_path = sys.argv[2] if len(sys.argv) > 2 else "silva_env_pairs_long.csv"
wide_path = sys.argv[3] if len(sys.argv) > 3 else "silva_env_pairs_wide.csv"

SUFFIX = re.compile(r"[-_ ](prd|prod|production|dev|development|tst|test|int|integration|stg|staging|uat|qa|pp|preprod)$", re.I)

ENV_LABELS = {
    "production": "Production",
    "prod": "Production",
    "prd": "Production",
    "development": "Development",
    "dev": "Development",
    "integration / test": "Integration / Test",
    "integration-test": "Integration / Test",
    "integration": "Integration / Test",
    "test": "Integration / Test",
    "tst": "Integration / Test",
    "int": "Integration / Test",
}

ENV_ORDER = ["Production", "Integration / Test", "Development"]


def normalise_env(value):
    v = (value or "").strip()
    return ENV_LABELS.get(v.lower(), v)


def env_for(row):
    for candidate in (row.get("offering_environment"), row.get("service_used_for")):
        if candidate and candidate.strip():
            return normalise_env(candidate)
    parts = [p.strip() for p in (row.get("offering") or "").split(" - ")]
    if len(parts) >= 4:
        return normalise_env(parts[-2])
    return "(unknown)"


def app_for(service):
    return SUFFIX.sub("", (service or "").strip()) or "(no service)"


pairs = defaultdict(list)
with open(in_path, newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        service = row.get("business_service", "")
        pairs[(app_for(service), env_for(row))].append({
            "business_service": service,
            "offering": row.get("offering", ""),
            "support_group": row.get("offering_support_group") or row.get("service_support_group", ""),
        })

with open(long_path, "w", newline="", encoding="utf-8") as out:
    writer = csv.writer(out)
    writer.writerow(["application", "environment", "business_service", "offering", "support_group"])
    for (app, env) in sorted(pairs):
        for item in pairs[(app, env)]:
            writer.writerow([app, env, item["business_service"], item["offering"], item["support_group"]])

envs = ENV_ORDER + sorted({env for (_, env) in pairs} - set(ENV_ORDER))
apps = sorted({app for (app, _) in pairs})
with open(wide_path, "w", newline="", encoding="utf-8") as out:
    writer = csv.writer(out)
    writer.writerow(["application"] + envs)
    for app in apps:
        cells = []
        for env in envs:
            items = pairs.get((app, env), [])
            services = sorted({i["business_service"] for i in items})
            if not services:
                cells.append("")
            elif len(services) == 1:
                cells.append(services[0])
            else:
                cells.append(f"{services[0]} (+{len(services) - 1} more)")
        writer.writerow([app] + cells)

print(f"{len(apps)} applications, {len(pairs)} application+environment pairs")
print(f"wrote {long_path} and {wide_path}")
