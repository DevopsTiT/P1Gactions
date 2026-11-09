# PagerDuty Disclosure Address

```
Need the address for the model-name sentence
  the disclosure file
    https://assurance.pagerduty.com/documents
    search PagerDuty Advance AI Disclosure
    download the latest row
  the four company names in the sentence
    https://www.pagerduty.com/subprocessors/
    section: generative AI features
  how PagerDuty tells you to open the file
    https://docs.pagerduty.com/ai-automation/advance
```

| What you need | Address |
|---|---|
| Disclosure library | https://assurance.pagerduty.com/documents |
| Assurance home | https://assurance.pagerduty.com/ |
| Company list behind the sentence | https://www.pagerduty.com/subprocessors/ |
| Steps to download the file | https://docs.pagerduty.com/ai-automation/advance |
| Product terms that name this site | https://www.pagerduty.com/product-specific-terms/ |

## Summary

The model versions live in a file on PagerDuty's Assurance Profile. Open https://assurance.pagerduty.com/documents and search for PagerDuty Advance AI Disclosure. The four company names in the sentence are on the public subprocessor page.

## Investigation

| Source | Address it gives |
|---|---|
| PagerDuty docs | Assurance Profile, then search PagerDuty Advance AI Disclosure. |
| Assurance site | https://assurance.pagerduty.com/documents |
| Product-specific terms | The AI Disclosure is located at assurance.pagerduty.com. |
| Subprocessor page | https://www.pagerduty.com/subprocessors/ |

The documents page does not publish one permanent PDF link for the disclosure. The download is the latest row after the search.

## Result

Open this first:

```
https://assurance.pagerduty.com/documents
```

In the search bar, type `PagerDuty Advance AI Disclosure`. Open the latest row and download it. The model names and versions are in that file.

The sentence you pasted uses the public company list. That list is here:

```
https://www.pagerduty.com/subprocessors/
```

On that page, use the section named "Additional service-specific subprocessors that may also be used in generative AI features".

## Data flow map

```
Row 4 sentence
        |
        +--> company names
        |      https://www.pagerduty.com/subprocessors/
        |
        +--> model versions
               https://assurance.pagerduty.com/documents
               search: PagerDuty Advance AI Disclosure
               download the latest file
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which address answers which part. |
| `1-investigation.md` | Where each address was found. |
| `2-result.md` | The two links to open. |
| `3-glossary.md` | The names. |
| `7-pagerduty-disclosure-address-follow.txt` | The same links for a phone. |
| `7.sh` | Copy commands. |

Commands: [7.sh](7.sh)
