# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Business service | The SILVA record for an application in one environment, such as `uk-sap-fscd-dev` | Each environment usually has its own |
| Service offering | A child of a business service that carries the environment and support level | The offering must belong to the chosen business service |
| parent | The field on an offering that points to its business service | This is what links environment and service |
| u_environment | The custom Environment field on the offering | The best source of the environment |
| used_for | The standard CMDB field for a CI's purpose (Production, Development and so on) | A backup environment source |
| Application stem | The service name without its env suffix | Groups dev, test and prd into one row |
| Long table | One row per application and environment | Easy to filter and complete |
| Wide table | One row per application, one column per environment | Easy to read side by side |
