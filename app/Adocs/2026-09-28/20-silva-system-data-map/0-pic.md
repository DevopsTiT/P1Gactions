# System Data Map Picture

```
problem -> system name?
  tag system/app/dt.cost.product -> security context -> entity names
  in SYSTEM_MAP?
    yes -> map values (blank value -> default)
    no  -> uk-sap-fscd-dev defaults
  group: TEST override -> AGO_AXA_SUPPORTGROUP -> L2 (map, else Ops_Middleware_Monitoring_AXAJP)
  business service changes -> edit SYSTEM_MAP only
```

```
EIP problem -> SYSTEM_MAP.EIP -> business service ALJ_EIP_PRD, env Production, group L2 default
```
