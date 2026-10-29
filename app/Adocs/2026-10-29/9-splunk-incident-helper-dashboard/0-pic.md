# Splunk Incident Helper Dashboard

```
Want a page like EIP/DIS Incident Helper
  one time range for the whole page → Last 15 minutes
  one box → one search → one picture
    a count → Single value
    a letter such as A → Single value
    host and status → Table
  color → set on that box
    failure box stays red
    success box stays green
  box says No results found → that search matched zero events
    open the search in Search
    widen the time
    check the host filter
```

```
Search by Time = Last 15 minutes
        |
        +--> APIGateway FAILURE search --> single value 538, red
        +--> APIGateway SUCCESS search --> single value 19187, green
        +--> IS Success search --> single value 0, green
        +--> IS Failure search --> single value 0, red
        |
        +--> Kappa hosts WPLALJ2BC WPLALJ2BB --> no events
        +--> Kappa ND mode search --> letter A
        +--> English hosts WPLALJ2CO WPLALJ2BF --> 536, red
        +--> English ND mode search --> letter A
        |
        +--> left mediator search --> no events
        +--> right mediator search --> two hosts, EIP_UP
        +--> left integration search --> no events
        +--> right integration search --> two hosts, EIP_UP
```
