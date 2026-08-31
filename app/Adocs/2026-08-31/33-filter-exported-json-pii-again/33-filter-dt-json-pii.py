#!/usr/bin/env python3
"""Second-pass filter on Dynatrace-exported JSON log rows.

Keeps records whose content looks like real PII field/value dumps.
Drops CleansingResult / cleansingResult noise.

Usage:
  python3 33-filter-dt-json-pii.py input.json output.json
  python3 33-filter-dt-json-pii.py input.json output-redacted.json --redact
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

KEEP_RE = re.compile(
    r"address,\s*Value\s*=|AddressKana|AddressKanji|kanjiFullAddress|"
    r"PERSON_ADDRESS|OFFICE_ADDRESS|Type\s*=\s*address|"
    r"postalCode,\s*Value\s*=|postal_code,\s*Value\s*=|"
    r"person_fullname|given_name,\s*Value\s*=|family_name,\s*Value\s*=|"
    r"holderName,\s*Value\s*=|displayName,\s*Value\s*=|"
    r"firstName,\s*Value\s*=|lastName,\s*Value\s*=|fullName,\s*Value\s*=|"
    r"customerName,\s*Value\s*=|"
    r"phoneNumber,\s*Value\s*=|phone_number,\s*Value\s*=|"
    r"mobileNumber,\s*Value\s*=|mobile_number,\s*Value\s*=|telNo,\s*Value\s*=|"
    r"emailAddress,\s*Value\s*=|email_address,\s*Value\s*=|mailAddress,\s*Value\s*=|"
    r"birthDate,\s*Value\s*=|dateOfBirth,\s*Value\s*=|myNumber,\s*Value\s*=|"
    r"bankAccount,\s*Value\s*=|accountNumber,\s*Value\s*=|cardNumber,\s*Value\s*=|"
    r"氏名|住所|電話番号|生年月日|郵便番号|メールアドレス",
    re.I,
)

DROP_RE = re.compile(r"CleansingResult|cleansingResult")

KEYWORD_LABELS = [
    ("address_value", re.compile(r"address,\s*Value\s*=", re.I)),
    ("AddressKana", re.compile(r"AddressKana")),
    ("person_fullname", re.compile(r"person_fullname", re.I)),
    ("phone", re.compile(r"phoneNumber,\s*Value\s*=|phone_number,\s*Value\s*=|mobileNumber,\s*Value\s*=|telNo,\s*Value\s*=", re.I)),
    ("email", re.compile(r"emailAddress,\s*Value\s*=|mailAddress,\s*Value\s*=", re.I)),
    ("birth", re.compile(r"birthDate,\s*Value\s*=|dateOfBirth,\s*Value\s*=", re.I)),
    ("myNumber", re.compile(r"myNumber,\s*Value\s*=", re.I)),
    ("jp_address", re.compile(r"住所|郵便番号")),
    ("jp_phone", re.compile(r"電話番号")),
    ("jp_name", re.compile(r"氏名")),
]


def unwrap_records(payload: Any) -> list[Any]:
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        for key in ("records", "data", "result", "results", "items", "logs"):
            value = payload.get(key)
            if isinstance(value, list):
                return value
        # single record object
        if "content" in payload:
            return [payload]
    raise SystemExit("Could not find a list of records in the JSON file")


def get_content(row: Any) -> str:
    if not isinstance(row, dict):
        return str(row)
    for key in ("content", "message", "log.content", "text"):
        if key in row and row[key] is not None:
            return str(row[key])
    # nested attributes
    attrs = row.get("attributes") or row.get("fields")
    if isinstance(attrs, dict) and attrs.get("content") is not None:
        return str(attrs["content"])
    return ""


def matched_keywords(content: str) -> list[str]:
    found = []
    for label, pattern in KEYWORD_LABELS:
        if pattern.search(content):
            found.append(label)
    return found


def redact_row(row: dict[str, Any], content: str) -> dict[str, Any]:
    return {
        "timestamp": row.get("timestamp") or row.get("start") or row.get("time"),
        "dt.host_group.id": row.get("dt.host_group.id")
        or (row.get("attributes") or {}).get("dt.host_group.id"),
        "host.name": row.get("host.name") or (row.get("attributes") or {}).get("host.name"),
        "matched_keywords": matched_keywords(content),
        "content_preview": content[:120].replace("\n", " ") + ("…" if len(content) > 120 else ""),
        "note": "full content omitted (redact mode)",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Filter Dynatrace JSON export for real PII-like rows")
    parser.add_argument("input_json")
    parser.add_argument("output_json")
    parser.add_argument("--redact", action="store_true", help="Do not write full content (ticket-safe)")
    args = parser.parse_args()

    in_path = Path(args.input_json)
    out_path = Path(args.output_json)
    payload = json.loads(in_path.read_text(encoding="utf-8"))
    records = unwrap_records(payload)

    kept: list[Any] = []
    for row in records:
        content = get_content(row)
        if not content:
            continue
        if DROP_RE.search(content):
            continue
        if not KEEP_RE.search(content):
            continue
        if args.redact and isinstance(row, dict):
            kept.append(redact_row(row, content))
        else:
            kept.append(row)

    out_path.write_text(json.dumps(kept, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"input_rows={len(records)} kept={len(kept)} output={out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
