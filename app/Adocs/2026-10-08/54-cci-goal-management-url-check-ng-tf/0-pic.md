# CCI Goal Management Pic

```
URL template on jenkins/test data → doesn't fit
source always "jenkins/test" → one row for all jobs
no status field → Response_Code empty → NG forever
→ rebuild on job_result per job (fails >= 2, oks == 0, 60m)
→ enabled = false until matched jobs are confirmed
```
