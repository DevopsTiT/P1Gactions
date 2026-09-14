# MQ metric events for ClaimCenter (Test) — cloned from ContactManager pattern
# metric filter: eq(app,cc)

resource "dynatrace_metric_events" "alerting_claimcenter_mq_failed_error" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Failed Messages Critical"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 failed messages (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "ERROR"
    title       = "ClaimCenter Test MQ Failed Messages - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 100
    samples           = 10
    violating_samples = 3
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.failed:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_failed_warning" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Failed Messages Warning"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has reached 10% of critical threshold for 10min (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "RESOURCE"
    title       = "ClaimCenter Test MQ Failed Messages Warning - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 10
    samples           = 10
    violating_samples = 10
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.failed:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_retry_error" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Retry Messages Critical"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 retry messages (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "ERROR"
    title       = "ClaimCenter Test MQ Retry Messages - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 100
    samples           = 10
    violating_samples = 3
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.retry:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_retry_warning" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Retry Messages Warning"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has reached 10% of critical threshold for 10min (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "RESOURCE"
    title       = "ClaimCenter Test MQ Retry Messages Warning - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 10
    samples           = 10
    violating_samples = 10
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.retry:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_inflight_error" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ In-Flight Messages Critical"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 in-flight messages (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "ERROR"
    title       = "ClaimCenter Test MQ In-Flight Messages - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 100
    samples           = 10
    violating_samples = 3
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.inflight:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_inflight_warning" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ In-Flight Messages Warning"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has reached 10% of critical threshold for 10min (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "RESOURCE"
    title       = "ClaimCenter Test MQ In-Flight Messages Warning - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 10
    samples           = 10
    violating_samples = 10
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.inflight:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_unsent_error" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Unsent Messages Critical"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has exceeded 100 unsent messages (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "ERROR"
    title       = "ClaimCenter Test MQ Unsent Messages - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 100
    samples           = 10
    violating_samples = 3
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.unsent:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}

resource "dynatrace_metric_events" "alerting_claimcenter_mq_unsent_warning" {
  enabled                      = true
  event_entity_dimension_key   = "queue.name"
  summary                      = "ClaimCenter Test MQ Unsent Messages Warning"

  event_template {
    description = "Queue {dims:queue.name} (ID: {dims:queue.id}) has reached 10% of critical threshold for 10min (current: {alert_condition:value})"
    davis_merge = false
    event_type  = "RESOURCE"
    title       = "ClaimCenter Test MQ Unsent Messages Warning - {dims:queue.name} (ID: {dims:queue.id})"
  }

  model_properties {
    type              = "STATIC_THRESHOLD"
    alert_condition   = "ABOVE"
    alert_on_no_data  = true
    threshold         = 10
    samples           = 10
    violating_samples = 10
    dealerting_samples = 5
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "guidewire.messaging.unsent:filter(eq(app,cc)):splitBy(\"queue.name\",\"queue.id\"):avg"
  }
}
