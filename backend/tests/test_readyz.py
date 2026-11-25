import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_readyz_endpoint(client: AsyncClient):
    response = await client.get("/readyz")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ("ready", "healthy")
    assert "database" in data
    assert "redis" in data
    assert data["database"]["status"] == "connected"
    assert data["database"]["healthy"] is True

@pytest.mark.asyncio
async def test_api_v1_readyz_endpoint(client: AsyncClient):
    response = await client.get("/api/v1/readyz")
    assert response.status_code == 200
    data = response.json()
    assert "database" in data
    assert "redis" in data

@pytest.mark.asyncio
async def test_redyz_endpoint(client: AsyncClient):
    # Test JSON response for /redyz
    response = await client.get("/redyz")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ("ready", "healthy")
    assert "database" in data
    assert "redis" in data
    assert data["database"]["status"] == "connected"

    # Test HTML response when browser requests text/html
    html_res = await client.get("/redyz", headers={"Accept": "text/html"})
    assert html_res.status_code == 200
    assert "text/html" in html_res.headers.get("content-type", "")
    assert "Database Connection" in html_res.text
    assert "Redis Connection" in html_res.text
