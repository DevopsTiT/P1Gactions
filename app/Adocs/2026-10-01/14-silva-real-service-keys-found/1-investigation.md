# Investigation

| What was checked | Evidence |
|---|---|
| C1 keys with service/ci | business_service, cmdb_ci, service_offering, u_business_service, u_lookup_b_service, u_so_dis_name, u_service_request, u_service_recovery_confirmation, u_ci_class and others |
| C2 values | u_business_service and u_lookup_b_service = 37273dbc...cbf8; cmdb_ci = cfbf255f...cb4b (offering name with "AXA XL - Production - Silver"); business_service and service_offering empty |
| C3 dictionary | cmdb_ci label "Service Offering"; u_business_service label "Business service"; business_service and service_offering labels start with "ZZZ-Do-not-use" |
| C4 | short_description EPAS Filter Error, assignment group InfraSupport_Dist-WindowsHK_L2_ASIA, u_environment Development |
| C5 prod | "User is not authenticated" |
| Workflow | build-payload sent business_service, service_offering, and host in cmdb_ci |
