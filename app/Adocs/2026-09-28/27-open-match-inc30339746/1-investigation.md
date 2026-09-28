# Investigation

| What was checked | Finding |
|---|---|
| INC30339746 form | CI ts12.hk.intraxa, business service and offering Third Party Services Monitoring Application, group InfraSupport_Dist-WindowsHK_L2_ASIA, environment Development, 4 - Low. |
| Summary headline | dt.event.description "EPAS Filter Error: All defined EPAS servers unreachable, applying default action". |
| JSON | isRootCause "false", dynatrace_severity CUSTOM_ALERT, properties in key order, "title" after tags, `"key" : value` spacing. |
| Tags | AGO_AXAENVIRONMENTNAME:Development, AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA, host:ts12, AGO_DOMAIN:hk.intraxa. |
| Seq 26 code | isRootCause was "true" whenever any entity existed; properties unsorted; no title key. |
