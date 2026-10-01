# P-261090 Investigation

| Evidence | Finding |
|---|---|
| Input event | Tags show Development, InfraSupport_Dist-WindowsHK_L2_ASIA, ATK, hk.intraxa, host ts12. No maintenance tag. |
| preview-silva-incident problems | "Service Offering (cmdb_ci): MISSING - mandatory on the SILVA form". |
| u_business_service source | "CI ts12.hk.intraxa -> cmdb_rel_ci (Depends on …)", service Distr-Windows-OS-JumpServer-AGO. |
| cmdb_ci source | "service offering: not found". |
| u_configuration_item | 1dfdcf8adb8dfa40251af9971d961941, same as INC30340215. |
| INC30340215 (seq 16) | u_business_service 37273dbc1b0f7c50114e0826464bcbf8, cmdb_ci cfbf255f1b03b49416deb166464bcb4b. |
| Code | serviceForCi returned only the first linked service, and no offering fallback matched. |
| Fix check | All three YAMLs parse and every task script passes node --check. |
