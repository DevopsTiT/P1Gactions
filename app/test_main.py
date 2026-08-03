from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_root():
    response = client.get("/")
    body = response.json()
    assert response.status_code == 200
    assert body["service"] == "github-actions-starter"
    assert "hello" in body["message"]
