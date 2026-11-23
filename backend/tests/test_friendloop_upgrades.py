import pytest
from datetime import date
from httpx import AsyncClient
from app.models.database_models import Profile, ProfileLanguage

@pytest.mark.asyncio
async def test_reels_and_rooms_and_wallet(client: AsyncClient, db_session):
    # Seed Aarav
    aarav = Profile(
        id="11111111-1111-1111-1111-111111111111",
        phone="+919876543210",
        display_name="Aarav Sharma",
        date_of_birth=date(1998, 5, 15),
        state_or_union_territory="Maharashtra",
        city="Mumbai",
        free_calls_remaining=5,
        coins=120,
        rules_accepted=True
    )
    db_session.add(aarav)
    db_session.add(ProfileLanguage(profile_id=aarav.id, language="Hindi"))
    await db_session.commit()

    # 1. List reels
    r = await client.get("/api/v1/reels", headers={"Authorization": "Bearer demo-token-aarav"})
    assert r.status_code == 200
    reels_data = r.json()
    assert len(reels_data) >= 1
    reel_id = reels_data[0]["id"]

    # 2. Like reel
    like_res = await client.post(f"/api/v1/reels/{reel_id}/like", headers={"Authorization": "Bearer demo-token-aarav"})
    assert like_res.status_code == 200
    assert "liked" in like_res.json()

    # 3. Add reel comment
    comm_res = await client.post(
        f"/api/v1/reels/{reel_id}/comments",
        headers={"Authorization": "Bearer demo-token-aarav"},
        json={"comment_text": "Awesome reel from Bengaluru!"}
    )
    assert comm_res.status_code == 201

    # 4. List rooms
    rooms_res = await client.get("/api/v1/rooms")
    assert rooms_res.status_code == 200
    assert len(rooms_res.json()) >= 1

    # 5. Create party room
    create_room_res = await client.post(
        "/api/v1/rooms",
        headers={"Authorization": "Bearer demo-token-aarav"},
        json={
            "title": "Weekend Party Hangout",
            "room_type": "voice",
            "activity_type": "ludo",
            "language": "Hindi",
            "access_type": "public",
            "entry_fee_coins": 10,
            "max_seats": 6
        }
    )
    assert create_room_res.status_code == 201

    # 6. Check wallet balance
    wallet_res = await client.get("/api/v1/wallet/balance", headers={"Authorization": "Bearer demo-token-aarav"})
    assert wallet_res.status_code == 200
    assert wallet_res.json()["coins"] == 120

    # 7. Buy coins pack_40 (40 coins for Rs. 9)
    buy_res = await client.post(
        "/api/v1/wallet/buy",
        headers={"Authorization": "Bearer demo-token-aarav"},
        json={"pack_id": "pack_40", "coins": 40, "price_inr": 9.0}
    )
    assert buy_res.status_code == 200
    assert buy_res.json()["coins"] == 160

    # 8. Plus subscription status and subscribe
    plus_res = await client.get("/api/v1/plus/status", headers={"Authorization": "Bearer demo-token-aarav"})
    assert plus_res.status_code == 200
    assert plus_res.json()["is_plus_subscriber"] is False

    sub_res = await client.post("/api/v1/plus/subscribe", headers={"Authorization": "Bearer demo-token-aarav"})
    assert sub_res.status_code == 200
    assert sub_res.json()["is_plus_subscriber"] is True
