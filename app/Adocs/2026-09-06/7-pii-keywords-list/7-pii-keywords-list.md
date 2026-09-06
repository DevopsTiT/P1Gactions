# PII Keywords List

```
Need PII keys for Dynatrace scan / blocklist?
  → Use list below (from your pii keys.txt)
  → Prefer JSON shape "key" when scanning
```

| Source | Path |
| --- | --- |
| Clean file | `../6-dynatrace-log-pii-identify-prevent/pii-keys-blocklist.txt` |
| Origin | `C:\Adocs\Notepad\pii keys.txt` (screenshots) |

## High-risk PII keys (names, DOB, address, contact, bank)

```
policyOwnerNameKana
policyOwnerDateOfBirth
bankOwnerNameKana
mail
email
EmailAddress1
contractPersonKanjiName
contractPersonKanaName
subscriberDOB
subscriberZipCode
subscriberAdress1
subscriberAdress2
subscriberAdress3
subscriberAdress4
holderKadress1
holderKadress2
holderKadress3
holderKadress4
holderAddress1
holderAddress
holderKaddress
holderName
holderNameKana
holderTel
holderZipCode
insuredPersonKanjiName
insuredPersonKanaName
insuredName
insuredNameKana
insuredBirthDate
policyHolderName
policyHolderNameKana
policyHolderBirthDate
policyHolder
policyNotificationAddressZipcode
policyNotificationAddress
policyNotificationTelNo
telephoneNumber
HomeNumber
bankCode
bankName
bankNo
branchCode
branchName
bankBranchNo
bankBranchName
bankAccountTypeName
bankAccountNo
depositorName
depositorNameKana
postalSavingsPassbookCode
PostalSavingsPassbookNo
deathBeneficiaryName
deathBeneficiaryNameKana
maturityBeneficiaryName
maturityBeneficiaryNameKana
benefitBeneficiaryName
benefitBeneficiaryNameKana
designatedRepresentativeName
designatedRepresentativeNameKana
cancerBeneficiaryName
initialEmployeeName
employeeName
employeeNameKana
name
given_name
family_name
DisplayName
FirstName
FirstNameKanji
LastName
LastNameKanji
PrimaryAddress
AddressLine1
AddressLine1Kanji
AddressLine2
City
CityKanji
PostalCode
PolicyAddress
locationAddress1
locationAddress2
address
addressKana
zipCode
oldAddressInfo
oldName
oldNameKana
oldBirthDate
oldNameInfo
requesterName
oneGenAgoName
twoGenAgoName
```

## Staff / org (often personal — include in scans)

```
salesSupervisorEmployeeName
personInCharge
personInChargeCode
salesPerson1
salesPerson2
salesPersonCode1
salesPersonCode2
departmentInCharge
departmentInChargeCode
salesBranchInCharge
salesBranchInChargeCode
salesBranchOfPerformance
salesBranchOfPerformanceCode
requesterId
marketStrategyCustomer
```

## Deferred (not in first blocklist)

Product/contract metadata — **do not include in first scan/mask wave** (revisit with privacy later):

`deathBeneficiaryGroup`, `deathBeneficiaryInfo`, `basicProductCoverageCode`, `shortenedProductName`, `typeIdentificationCode`, `typeIdentificationCodeName`, `familySpecialRegulationCode`, `familySpecialRegulationCodeName`, `contractDate`, `insurancePeriod`, `insurancePeriodTypeCodeName`, `pCollectionPeriod`, `pCollectionTypeCodeName`, `pCollectionEndDate`, `maturityDate`, `basicProductSumInsured`, `totalPremium`, `riderPremium`, `policyNotificationAddressUnknownFlag`, `PeriodStartDate`

## Data flow

```
pii keys.txt → blocklist → DQL scan / OpenPipeline / app deny-list
```

## Related

| File | Purpose |
| --- | --- |
| `../6-dynatrace-log-pii-identify-prevent/pii-keys-blocklist.txt` | One key per line |
| `../6-dynatrace-log-pii-identify-prevent/pii-scan.dql` | Scan query |
