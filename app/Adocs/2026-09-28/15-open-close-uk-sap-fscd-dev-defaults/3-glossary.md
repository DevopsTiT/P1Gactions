# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Business service | The SNOW service record for the incident. | Now uk-sap-fscd-dev. |
| Service offering | Offer record under the business service, per company, environment and offer type. | Must be the full Name ending in "Development - Standard". |
| Offer (Standard) | The offer type on the offering record. | Part of the full Name. |
| Hardcoded secret | A password or key written directly in the file. | Anyone with the file can use it, so keep it out of git. |
| .gitignore | File that tells git which files to skip. | Stops the YAMLs with secrets from being committed. |
