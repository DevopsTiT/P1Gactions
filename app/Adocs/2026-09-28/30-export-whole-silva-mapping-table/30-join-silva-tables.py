import csv
import sys
from collections import defaultdict

ci_path = sys.argv[1] if len(sys.argv) > 1 else "silva_ci_service.csv"
offering_path = sys.argv[2] if len(sys.argv) > 2 else "silva_service_offerings.csv"
out_path = sys.argv[3] if len(sys.argv) > 3 else "silva_whole_table.csv"

offerings = defaultdict(list)
with open(offering_path, newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        offerings[row["business_service"].strip()].append(row)

columns = [
    "host", "host_fqdn", "host_class", "host_status", "host_support_group",
    "business_service", "service_support_group", "service_status",
    "offering", "offering_environment", "offering_support_group", "company",
]

rows_out = 0
with open(ci_path, newline="", encoding="utf-8") as f, open(out_path, "w", newline="", encoding="utf-8") as out:
    writer = csv.DictWriter(out, fieldnames=columns)
    writer.writeheader()
    for row in csv.DictReader(f):
        base = {k: row.get(k, "") for k in columns[:8]}
        matches = offerings.get(base["business_service"].strip()) or [{}]
        for off in matches:
            writer.writerow({
                **base,
                "offering": off.get("offering", ""),
                "offering_environment": off.get("offering_environment", ""),
                "offering_support_group": off.get("offering_support_group", ""),
                "company": off.get("company", ""),
            })
            rows_out += 1

print(f"wrote {rows_out} rows to {out_path}")
