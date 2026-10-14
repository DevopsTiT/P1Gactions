# PayWithCreditCard DQL Final Investigation

| Item | Finding |
|---|---|
| URL field | Full URL, so `contains()` is needed. |
| Host field | Pod name, so `startsWith(src, "portals-amp-backend")`. |
| Escaping | May or may not be present in Dynatrace, so cleaning is conditional. |
| Speed | Text pre-filter before JSON parse. |
| Data | Not onboarded yet (answer 21). |
