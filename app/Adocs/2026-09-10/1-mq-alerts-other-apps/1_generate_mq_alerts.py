#!/usr/bin/env python3
"""Generate ContactManager-style MQ dynatrace_metric_events TF for other apps."""

from pathlib import Path

# Guidewire InsuranceSuite apps that use guidewire.messaging.* (same pattern as CM)
APPS = [
    # folder_slug, display_name, metric app dimension, env label in summary
    ("billingcenter", "BillingCenter", "bc", "Test"),
    ("claimcenter", "ClaimCenter", "cc", "Test"),
    ("policycenter", "PolicyCenter", "pc", "Test"),
]

# Metrics covered in alerting_contactmanager_mq.tf (from screenshots)
METRICS = [
    ("failed", "Failed"),
    ("retry", "Retry"),
    ("inflight", "In-Flight"),
    ("unsent", "Unsent"),
]


def resource_block(app_slug: str, display: str, app_code: str, env: str, metric_key: str, metric_label: str, severity: str) -> str:
    """severity: error | warning"""
    res = f"alerting_{app_slug}_mq_{metric_key}_{severity}"
    if severity == "error":
        summary = f"{display} {env} MQ {metric_label} Messages Critical"
        title = f"{display} {env} MQ {metric_label} Messages - {{dims:queue.name}} (ID: {{dims:queue.id}})"
        desc = (
            f"Queue {{dims:queue.name}} (ID: {{dims:queue.id}}) has exceeded 100 "
            f"{metric_key} messages (current: {{alert_condition:value}})"
        )
        # In-Flight wording in CM uses "in-flight" in description
        if metric_key == "inflight":
            desc = (
                "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 "
                "in-flight messages (current: {alert_condition:value})"
            )
        elif metric_key == "failed":
            desc = (
                "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 "
                "failed messages (current: {alert_condition:value})"
            )
        elif metric_key == "retry":
            desc = (
                "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 "
                "retry messages (current: {alert_condition:value})"
            )
        elif metric_key == "unsent":
            desc = (
                "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 "
                "unsent messages (current: {alert_condition:value})"
            )
        event_type = "ERROR"
        threshold = 100
        violating = 3
    else:
        summary = f"{display} {env} MQ {metric_label} Messages Warning"
        title = f"{display} {env} MQ {metric_label} Messages Warning - {{dims:queue.name}} (ID: {{dims:queue.id}})"
        desc = (
            "Queue {dims:queue.name} (ID: {dims:queue.id}) has reached 10% of critical "
            "threshold for 10min (current: {alert_condition:value})"
        )
        event_type = "RESOURCE"
        threshold = 10
        violating = 10

    selector = (
        f'guidewire.messaging.{metric_key}:filter(eq(app,{app_code}))'
        f':splitBy(\\"queue.name\\",\\"queue.id\\"):avg'
    )

    return f'''resource "dynatrace_metric_events" "{res}" {{
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "{summary}"

  event_template {{
    description = "{desc}"
    davis_merge = false
    event_type  = "{event_type}"
    title       = "{title}"
  }}

  model_properties {{
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = {threshold}
    samples           = 10
    violating_samples = {violating}
    dealerting_samples = 5
  }}

  query_definition {{
    type            = "METRIC_SELECTOR"
    metric_selector = "{selector}"
  }}
}}
'''


def render_app(app_slug: str, display: str, app_code: str, env: str) -> str:
    parts = [
        f"# MQ metric events for {display} ({env}) — cloned from ContactManager pattern",
        f"# metric filter: eq(app,{app_code})",
        "",
    ]
    for metric_key, metric_label in METRICS:
        parts.append(resource_block(app_slug, display, app_code, env, metric_key, metric_label, "error"))
        parts.append(resource_block(app_slug, display, app_code, env, metric_key, metric_label, "warning"))
    return "\n".join(parts)


def provider_tf(app_slug: str, env: str = "test") -> str:
    return f'''terraform {{
  required_providers {{
    dynatrace = {{
      source  = "dynatrace-oss/dynatrace"
      version = "~> 1.30.0"
    }}
  }}

  backend "s3" {{
    bucket       = "axa-li-jp-dynatrace-as-code-dev"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
    key          = "applications/{app_slug}/{env}/terraform.tfstate"
  }}
}}

provider "dynatrace" {{
}}
'''


def main():
    here = Path(__file__).resolve().parent
    out_root = here / "applications"
    # Also emit ContactManager reference reconstruction
    all_apps = [("contactmanager", "ContactManager", "cm", "Test")] + APPS

    for slug, display, code, env in all_apps:
        dest = out_root / slug / "test"
        dest.mkdir(parents=True, exist_ok=True)
        (dest / f"alerting_{slug}_mq.tf").write_text(render_app(slug, display, code, env), encoding="utf-8")
        # provider only if missing pattern needed for new apps
        if slug != "contactmanager":
            (dest / "provider.tf").write_text(provider_tf(slug, "test"), encoding="utf-8")
        print(f"wrote {dest / f'alerting_{slug}_mq.tf'}")


if __name__ == "__main__":
    main()
