# Glossary

| Term | What it means | Why you care on this slide |
|---|---|---|
| ALJ | AXA Life Japan. The monitoring page also covers ADJ (P&C). | The tool list is for this estate. |
| Five areas | APM, real user monitoring, synthetic, logs, and cloud/host infra. | These are the detectors in answer 2. |
| APM | Application performance monitoring. How fast and how healthy the app is. | Dynatrace OneAgent is the tool named for this. |
| RUM | Real user monitoring. What the person in the browser actually experiences. | Dynatrace DEM is the tool named for this. |
| DEM | Dynatrace Digital Experience Monitoring. Also the name of the database-monitoring row on the sheet. | One row is owned by the DBA team and points at Shinagawa DC. |
| OneAgent | The Dynatrace agent that sees the application and its host together. | Area 1 on the Confluence page. |
| Synthetic | A script that pretends to be a user and checks if the journey works. | Selenium/Jenkins and Dynatrace DEM. |
| Splunk | Log search and dashboards. | Area 4. Owner Technology DevOps. |
| VeloCloud | Network performance tool for the Japan network. | Named under cloud/infra on the page, and on the network rows. |
| Nagios | Network monitoring for the Japan ALJ network. | By default. Technology Network Team. |
| Aruba UXI | Checks network and Wi-Fi from selected sales offices. | Only some offices. |
| SCOM | Microsoft tool that watches VM CPU, memory, disk, and OS. | Owner on the sheet is Axa GO. |
| Cloud Broker | The team named as owner of CloudWatch, X-Ray, Prometheus, and Kibana. | They join only when the app uses AWS or Open PaaS. |
| PagerDuty | The escalation and notification tool for the 24x7 process. | Call, SMS, and the escalation policy. |
| Escalation policy | The rule for who is contacted next if the first person does not acknowledge. | Drawn on the PagerDuty step of the diagram. |
| BAM-India | The 24x7 desk that receives the notification on the diagram. | First human touch after the page. |
| War room | The bridge where Technology SREs and Application Support work the incident. | This is where context is written by hand. |
| Technology DevOps | Owner of Dynatrace, Splunk, Jenkins/Selenium, and PagerDuty. | The team that would sponsor this Gate 0 item. |
| ServiceNow | IT service-management tool drawn next to Silva. | Correlation step on the diagram. |
| Silva | The ticket and incident platform drawn with ServiceNow. | Keep it as the correlation step on the diagram. |
| To Be | The diagram’s own label. It is the target integrated flow. | Say that when you paste the seven steps. |
| PlaaS | Platform name printed on the tool sheet (PlaaS/Mgmt Zone, PlaaS/Internal PIC). | Use the sheet’s spelling. |
| PagerDuty AI | Assist that can brief people in Microsoft Teams after an incident exists. | Put that on a later slide. This monitoring page draws the 24x7 flow. |
