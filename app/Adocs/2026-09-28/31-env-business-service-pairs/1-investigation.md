# Investigation

| What was checked | Finding |
|---|---|
| Example ticket defaults | `uk-sap-fscd-dev` goes with offering "uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard". The environment is visible in both the service suffix and the offering name. |
| Abhay's example | `ALJ_EIP_PRD` is the Production business service for EIP, which suggests a separate service per environment. |
| Which table ties the environment to a service | `service_offering` (parent = business service, Environment field). |
| Backup environment sources | The business service's `used_for` field, and the 3rd part of the offering name. |
| Linking dev and prd of one application | SILVA has no guaranteed link, so the script groups by the name stem after removing the env suffix. |
| Commands run | None. Everything is in `31.sh`. |
