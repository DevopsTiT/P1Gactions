# API Gateway Success Pivot

```
Edit Search titled APIGateway SUCCESS
  same shape as APIGateway FAILURE
  data model → APIGW1015_Success_count
  count(RootObject) → one number
  time → shared picker searchByTimer
  refresh → every 1 minute
  green color → set on the chart
  confirm the model constraint
    failure model uses Status=FAILURE
    this model name is Success_count
    open the model before treating the filter as Status=SUCCESS
```

```
mediator server log
        |
        +--> data model APIGW1015_Failure_count
        |      Status=FAILURE
        |      red number
        |
        +--> data model APIGW1015_Success_count
               count(RootObject)
               shared time picker
               refresh 1 minute
               green number
```
