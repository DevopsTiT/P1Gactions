# Investigation

| What was checked | Finding |
|---|---|
| INC30339531 form | CI wrgcrapp01.axa-id.intraxa; business service and offering "Third Party Services Monitoring Application"; group InfraSupport_Dist-WindowsID_L2_ASIA; environment Integration / Test; 4 - Low. |
| Summary JSON | Keys correlation_id (entity id), discovered_name, dynatrace_severity, environmentId, environmentName, event_properties, ip_addresses, isRootCause, managementZones, metricName, problemDescription, problem_displayId, problem_id, tags, u_business_service, u_external_url. |
| Tags | AGO_AXA_SUPPORTGROUP, AGO_DEFAULT_ASSIGNMENT_GROUP, AGO_AXAENVIRONMENTNAME:Integration-Test, AGO_DOMAIN, host:wrgcrapp01, env:ACC. |
| Conclusion | SILVA derives business service from the CI; group and environment come from AGO tags. |
