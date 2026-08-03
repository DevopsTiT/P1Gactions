from datetime import datetime, timezone

from fastapi import FastAPI

app = FastAPI(title="github-actions-starter")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def root():
    return {
        "service": "github-actions-starter",
        "message": "hello from GitHub Actions",
        "time_utc": datetime.now(timezone.utc).isoformat(),
    }

