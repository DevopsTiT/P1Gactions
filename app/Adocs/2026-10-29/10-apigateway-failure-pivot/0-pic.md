# API Gateway Failure Pivot

```
Edit Search on APIGateway FAILURE
  search starts with pivot
    data model → APIGW1015_Failure_count
    object → RootObject
    count(RootObject) → one number
  time → Shared Time Picker token searchByTimer
  refresh → every 1 minute
  progress bar → shown while the search runs
  red color → set on the chart, outside this dialog
  Apply → saves the panel
  want the same box for another count
    clone the panel
    change the title
    change the data model name in the pivot
```

```
Dashboard time input
 token searchByTimer
 Last 15 minutes, or the range currently selected
        |
        v
APIGateway FAILURE panel
 every 1 minute
        |
        v
pivot data model APIGW1015_Failure_count
 object RootObject
        |
        v
count(RootObject) → one number
        |
        v
Single value chart
 title APIGateway FAILURE
 color set on the chart
```
