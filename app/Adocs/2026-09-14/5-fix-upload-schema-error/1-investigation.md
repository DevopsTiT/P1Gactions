# Investigation

| Evidence | Finding |
| --- | --- |
| Error 400 JSON | Invalid position.y, categories/entityTags arrays, forbidden trigger keys |
| Connection UI | ServiceNowTest → https://silvastg.service-now.com OAuth |
| External Requests banner | Must allow SNOW URL for outbound |

Fixed Connection pack YAML/JSON accordingly.
