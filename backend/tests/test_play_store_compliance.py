import pytest
from datetime import date, timedelta
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_18_plus_registration_enforcement(client: AsyncClient, db_session):
    # 1. Login with demo phone to get token
    res = await client.post("/api/v1/auth/verify-otp", json={"phone": "+919876543210", "otp": "123456"})
    assert res.status_code == 200
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Try to register with DOB under 18 (e.g. born 10 years ago)
    minor_dob = (date.today() - timedelta(days=365 * 10)).isoformat()
    res_minor = await client.post(
        "/api/v1/auth/profile",
        headers=headers,
        json={
            "display_name": "Minor Test",
            "date_of_birth": minor_dob,
            "state_or_union_territory": "Karnataka",
            "city": "Bengaluru",
            "languages": ["English"],
            "rules_accepted": True,
        }
    )
    # Must be rejected (either 422 from schema or 400 from endpoint)
    assert res_minor.status_code in [400, 422]
    error_msg = str(res_minor.json())
    assert "18" in error_msg

    # 3. Register with adult DOB (born 22 years ago)
    adult_dob = (date.today() - timedelta(days=365 * 22)).isoformat()
    res_adult = await client.post(
        "/api/v1/auth/profile",
        headers=headers,
        json={
            "display_name": "Adult Test",
            "date_of_birth": adult_dob,
            "state_or_union_territory": "Karnataka",
            "city": "Bengaluru",
            "languages": ["English"],
            "rules_accepted": True,
        }
    )
    assert res_adult.status_code == 200
    assert res_adult.json()["age"] >= 18
    assert res_adult.json()["is_adult"] is True

@pytest.mark.asyncio
async def test_user_choice_billing_and_alternative_billing(client: AsyncClient, db_session):
    res = await client.post("/api/v1/auth/verify-otp", json={"phone": "+919876543210", "otp": "123456"})
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Buy coins via Google Play Billing
    buy_play = await client.post(
        "/api/v1/wallet/buy",
        headers=headers,
        json={
            "pack_id": "pack_100",
            "coins": 100,
            "price_inr": 19.0,
            "payment_method": "google_play"
        }
    )
    assert buy_play.status_code == 200
    assert buy_play.json()["coins"] >= 100

    # 2. Buy coins via Alternative Billing (Razorpay)
    buy_alt = await client.post(
        "/api/v1/wallet/buy",
        headers=headers,
        json={
            "pack_id": "pack_40",
            "coins": 40,
            "price_inr": 9.0,
            "payment_method": "alternative_razorpay"
        }
    )
    assert buy_alt.status_code == 200

    # 3. Subscribe Plus via User Choice Billing
    sub_res = await client.post(
        "/api/v1/plus/subscribe",
        headers=headers,
        json={"payment_method": "alternative_razorpay"}
    )
    assert sub_res.status_code == 200
    assert sub_res.json()["is_plus_subscriber"] is True

@pytest.mark.asyncio
async def test_public_and_in_app_deletion_and_child_safety(client: AsyncClient, db_session):
    # Public Child Safety page
    cs_page = await client.get("/child-safety")
    assert cs_page.status_code == 200
    assert "Child Safety Standards" in cs_page.text
    assert "safety@friendloop.app" in cs_page.text

    # Public Account Deletion page
    del_page = await client.get("/delete-account")
    assert del_page.status_code == 200
    assert "Account & Data Deletion" in del_page.text

    # Public deletion request API
    pub_del = await client.post(
        "/api/v1/public/delete-account-request",
        json={"phone": "+919876543210", "reason": "Test Play Store compliance"}
    )
    assert pub_del.status_code == 200
    assert pub_del.json()["success"] is True

    # Reporting endpoint
    res = await client.post("/api/v1/auth/verify-otp", json={"phone": "+919876543211", "otp": "123456"})
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    report = await client.post(
        "/api/v1/moderation/report",
        headers=headers,
        json={
            "target_type": "reel",
            "target_id": "test_reel_123",
            "reason": "Inappropriate Content"
        }
    )
    assert report.status_code == 200
