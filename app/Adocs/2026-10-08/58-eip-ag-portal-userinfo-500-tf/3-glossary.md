# EIP UserInfo 500 Glossary

| Term | What it means | Why you care |
|---|---|---|
| EIP | The enterprise integration platform, an API gateway between systems | It logs every call, which is where the 500s are seen |
| API_VERSION | The EIP name of the API being called | Picks out UserInfoService from other APIs |
| HTTP 500 | Internal server error from the called service | AG Portal failed to answer Compass |
| Throttle | Splunk setting that mutes repeat alerts for a while | Dynatrace gets the same effect from one open problem |
| Search-time field | A field Splunk extracts when searching | It may not exist as an attribute in Dynatrace |
