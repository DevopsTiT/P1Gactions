# User question (verbatim)

give me how to filter pii in dynatrace use this info

They attached a screenshot of Excel "Prod-HostGroupUpdate 1 - Kim" with HostNames sheet showing production servers, dt.host_group.id, Application Name, owners, planned dates.

Extract from image all visible:
- Hostnames (e.g. *-HFTP-01.ads-jp.intraxa, S-HQFS-01, EAA0059.PRPRIVMGMT.intra, etc.)
- dt.host_group.id values (C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE, C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP, C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP, C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE, etc.)
- Application names (FTP SSTB, DFS, People Soft HR, Customer Master Data Management, Enterprise Integration Platform, Hulft, Tax Payment Report Management, imageWARE Form Manager, BC calc, etc.)
- Owner column (Magaki, etc.)

Deliverable: practical guide for filtering/masking PII in Dynatrace scoped to this host group / application inventory.
