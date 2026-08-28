# Question — Seq 17

**Date:** 2026-08-28  
**Verbatim:** dt group should use colume L, change everything

**Context:** Excel `Prod-HostGroupUpdate` HostNames sheet. Column B (`dt host_group_id`) still has old values like `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`. Column L (`manual change value`) has the correct per-app host group IDs from formula `="C_ALJ_BU_" & D & "_A_" & E & "_E_" & F & "_T_" & G`.

**Ask:** Update all DQL host group filters and documentation to use column L instead of column B.
