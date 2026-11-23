import pytest
import uuid
from datetime import date, datetime, timedelta, timezone
from app.models.database_models import Profile, ProfileLanguage, CallSession, CallParticipant, Friendship, Block, Pass
from app.core.security import create_staff_token, create_access_token

def uid():
    return str(uuid.uuid4())

@pytest.mark.asyncio
async def test_underage_and_suspended_registration(client, db_session):
    u_id = uid()
    # 1. Underage DOB rejection
    underage_payload = {
        "display_name": "Teen User",
        "date_of_birth": (date.today() - timedelta(days=365 * 16)).isoformat(), # 16 years old
        "state_or_union_territory": "Delhi",
        "languages": ["Hindi"],
        "rules_accepted": True
    }
    # Create placeholder user
    p = Profile(
        id=u_id,
        phone="+919999900001",
        display_name="Temp",
        date_of_birth=date(2010, 1, 1),
        state_or_union_territory="Delhi",
        free_calls_remaining=5
    )
    db_session.add(p)
    await db_session.commit()

    token = create_access_token({"sub": p.id})
    res = await client.post(
        "/api/v1/auth/profile",
        json=underage_payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert res.status_code == 422 # Pydantic validation error: must be 18+

    # 2. Suspended user cannot queue
    p.date_of_birth = date(1995, 1, 1)
    p.is_suspended = True
    p.suspension_reason = "Harassment violation"
    p.rules_accepted = True
    await db_session.commit()

    res = await client.post(
        "/api/v1/match/join",
        json={"call_mode": "voice"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert res.status_code == 400
    assert "suspended" in res.json()["detail"].lower()

@pytest.mark.asyncio
async def test_matching_across_states_and_languages(client, db_session):
    id_a = uid()
    id_b = uid()
    # User A: Maharashtra (Hindi, English)
    user_a = Profile(
        id=id_a,
        phone="+919876543210",
        display_name="Aarav",
        date_of_birth=date(1998, 1, 1),
        state_or_union_territory="Maharashtra",
        free_calls_remaining=5,
        rules_accepted=True
    )
    # User B: Karnataka (Hindi, Kannada)
    user_b = Profile(
        id=id_b,
        phone="+919876543211",
        display_name="Priya",
        date_of_birth=date(1999, 1, 1),
        state_or_union_territory="Karnataka",
        free_calls_remaining=5,
        rules_accepted=True
    )
    db_session.add_all([user_a, user_b])
    db_session.add(ProfileLanguage(profile_id=user_a.id, language="Hindi"))
    db_session.add(ProfileLanguage(profile_id=user_a.id, language="English"))
    db_session.add(ProfileLanguage(profile_id=user_b.id, language="Hindi"))
    db_session.add(ProfileLanguage(profile_id=user_b.id, language="Kannada"))
    await db_session.commit()

    token_a = create_access_token({"sub": user_a.id})
    token_b = create_access_token({"sub": user_b.id})

    # User A joins queue
    res_a = await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {token_a}"})
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert data_a["in_queue"] is True
    assert data_a["matched_session"] is None

    # User B joins queue -> Should match across states!
    res_b = await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {token_b}"})
    assert res_b.status_code == 200
    data_b = res_b.json()
    assert data_b["in_queue"] is False
    assert data_b["matched_session"] is not None
    assert data_b["matched_session"]["partner"]["display_name"] == "Aarav"
    assert data_b["matched_session"]["partner"]["state_or_union_territory"] == "Maharashtra"

@pytest.mark.asyncio
async def test_failed_unanswered_calls_preserve_credits(client, db_session):
    user = Profile(
        id=uid(),
        phone="+919876543212",
        display_name="Rohan",
        date_of_birth=date(1997, 1, 1),
        state_or_union_territory="Gujarat",
        free_calls_remaining=5,
        rules_accepted=True
    )
    db_session.add(user)
    db_session.add(ProfileLanguage(profile_id=user.id, language="Hindi"))
    await db_session.commit()

    token = create_access_token({"sub": user.id})

    # 1. Join queue and cancel search -> 0 credits used
    await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {token}"})
    res_cancel = await client.post("/api/v1/match/cancel", headers={"Authorization": f"Bearer {token}"})
    assert res_cancel.status_code == 200
    assert "Zero credits consumed" in res_cancel.json()["message"]

    await db_session.refresh(user)
    assert user.free_calls_remaining == 5

@pytest.mark.asyncio
async def test_connected_call_starts_60s_timer_and_charges_credit_idempotently(client, db_session):
    u1 = Profile(id=uid(), phone="+919876500001", display_name="User1", date_of_birth=date(1995, 1, 1), state_or_union_territory="Punjab", free_calls_remaining=5, rules_accepted=True)
    u2 = Profile(id=uid(), phone="+919876500002", display_name="User2", date_of_birth=date(1996, 1, 1), state_or_union_territory="Delhi", free_calls_remaining=5, rules_accepted=True)
    db_session.add_all([u1, u2])
    db_session.add(ProfileLanguage(profile_id=u1.id, language="Punjabi"))
    db_session.add(ProfileLanguage(profile_id=u2.id, language="Punjabi"))
    await db_session.commit()

    t1 = create_access_token({"sub": u1.id})
    t2 = create_access_token({"sub": u2.id})

    # Match them
    await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t1}"})
    match_res = await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t2}"})
    room_id = match_res.json()["matched_session"]["room_id"]

    # Participant 1 connects
    c1 = await client.post("/api/v1/calls/connect", json={"room_id": room_id}, headers={"Authorization": f"Bearer {t1}"})
    assert c1.status_code == 200
    assert c1.json()["status"] == "connecting" # Only 1 participant connected so far

    # Credits still 5
    await db_session.refresh(u1)
    await db_session.refresh(u2)
    assert u1.free_calls_remaining == 5
    assert u2.free_calls_remaining == 5

    # Participant 2 connects -> BOTH connected!
    c2 = await client.post("/api/v1/calls/connect", json={"room_id": room_id}, headers={"Authorization": f"Bearer {t2}"})
    assert c2.status_code == 200
    sess = c2.json()
    assert sess["status"] == "connected"
    assert sess["shared_end_time"] is not None

    # Credits decremented by exactly 1
    await db_session.refresh(u1)
    await db_session.refresh(u2)
    assert u1.free_calls_remaining == 4
    assert u2.free_calls_remaining == 4

    # Simultaneous / duplicate webhook or connect callback must NOT double charge
    c1_dup = await client.post("/api/v1/calls/connect", json={"room_id": room_id}, headers={"Authorization": f"Bearer {t1}"})
    assert c1_dup.status_code == 200
    await db_session.refresh(u1)
    assert u1.free_calls_remaining == 4 # Still 4, idempotent!

@pytest.mark.asyncio
async def test_reconnect_preserves_call_deadline(client, db_session):
    u1 = Profile(id=uid(), phone="+919876500003", display_name="RecUser1", date_of_birth=date(1995, 1, 1), state_or_union_territory="Kerala", free_calls_remaining=5, rules_accepted=True)
    u2 = Profile(id=uid(), phone="+919876500004", display_name="RecUser2", date_of_birth=date(1996, 1, 1), state_or_union_territory="Goa", free_calls_remaining=5, rules_accepted=True)
    db_session.add_all([u1, u2])
    db_session.add(ProfileLanguage(profile_id=u1.id, language="English"))
    db_session.add(ProfileLanguage(profile_id=u2.id, language="English"))
    await db_session.commit()

    t1 = create_access_token({"sub": u1.id})
    t2 = create_access_token({"sub": u2.id})

    await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t1}"})
    match_res = await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t2}"})
    room_id = match_res.json()["matched_session"]["room_id"]

    await client.post("/api/v1/calls/connect", json={"room_id": room_id}, headers={"Authorization": f"Bearer {t1}"})
    c2 = await client.post("/api/v1/calls/connect", json={"room_id": room_id}, headers={"Authorization": f"Bearer {t2}"})
    original_deadline = c2.json()["shared_end_time"]

    # Participant 1 briefly drops and reconnects
    rec_res = await client.get(f"/api/v1/calls/reconnect/{room_id}", headers={"Authorization": f"Bearer {t1}"})
    assert rec_res.status_code == 200
    rec_data = rec_res.json()
    assert rec_data["status"] == "connected"
    assert rec_data["shared_end_time"] == original_deadline
    assert 50 <= rec_data["remaining_seconds"] <= 60

@pytest.mark.asyncio
async def test_unilateral_vs_mutual_friend_choice(client, db_session):
    u1 = Profile(id=uid(), phone="+919876500005", display_name="Friend1", date_of_birth=date(1995, 1, 1), state_or_union_territory="Rajasthan", free_calls_remaining=5, rules_accepted=True)
    u2 = Profile(id=uid(), phone="+919876500006", display_name="Friend2", date_of_birth=date(1996, 1, 1), state_or_union_territory="Assam", free_calls_remaining=5, rules_accepted=True)
    db_session.add_all([u1, u2])
    db_session.add(ProfileLanguage(profile_id=u1.id, language="Hindi"))
    db_session.add(ProfileLanguage(profile_id=u2.id, language="Hindi"))
    await db_session.commit()

    t1 = create_access_token({"sub": u1.id})
    t2 = create_access_token({"sub": u2.id})

    await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t1}"})
    match_res = await client.post("/api/v1/match/join", json={"call_mode": "voice"}, headers={"Authorization": f"Bearer {t2}"})
    call_id = match_res.json()["matched_session"]["id"]

    # 1. Unilateral choice by User 1
    fc1 = await client.post(
        "/api/v1/friendships/choose",
        json={"call_id": call_id, "target_id": u2.id},
        headers={"Authorization": f"Bearer {t1}"}
    )
    assert fc1.status_code == 200
    data1 = fc1.json()
    assert data1["choice_recorded"] is True
    assert data1["is_mutual"] is False # Kept private!
    assert data1["friendship_id"] is None

    # Friends list of u2 should still be empty
    friends_u2 = await client.get("/api/v1/friendships", headers={"Authorization": f"Bearer {t2}"})
    assert len(friends_u2.json()) == 0

    # 2. Reciprocal choice by User 2 -> Mutual! Exactly 1 friendship created
    fc2 = await client.post(
        "/api/v1/friendships/choose",
        json={"call_id": call_id, "target_id": u1.id},
        headers={"Authorization": f"Bearer {t2}"}
    )
    assert fc2.status_code == 200
    data2 = fc2.json()
    assert data2["is_mutual"] is True
    assert data2["friendship_id"] is not None

    # Both now see the friendship
    friends_u1 = await client.get("/api/v1/friendships", headers={"Authorization": f"Bearer {t1}"})
    friends_u2 = await client.get("/api/v1/friendships", headers={"Authorization": f"Bearer {t2}"})
    assert len(friends_u1.json()) == 1
    assert len(friends_u2.json()) == 1
    assert friends_u1.json()[0]["friend_id"] == u2.id
    assert friends_u2.json()[0]["friend_id"] == u1.id

@pytest.mark.asyncio
async def test_private_chat_and_blocking(client, db_session):
    u1 = Profile(id=uid(), phone="+919876500007", display_name="Chatter1", date_of_birth=date(1995, 1, 1), state_or_union_territory="Telangana", free_calls_remaining=5, rules_accepted=True)
    u2 = Profile(id=uid(), phone="+919876500008", display_name="Chatter2", date_of_birth=date(1996, 1, 1), state_or_union_territory="Tamil Nadu", free_calls_remaining=5, rules_accepted=True)
    fs = Friendship(id=uid(), user_id1=u1.id, user_id2=u2.id, status="active")
    db_session.add_all([u1, u2, fs])
    await db_session.commit()

    t1 = create_access_token({"sub": u1.id})
    t2 = create_access_token({"sub": u2.id})

    # Send message from u1 to u2
    msg_res = await client.post(
        "/api/v1/messages",
        json={"friendship_id": fs.id, "content": "Namaste! Great meeting you on the call."},
        headers={"Authorization": f"Bearer {t1}"}
    )
    assert msg_res.status_code == 200
    assert msg_res.json()["content"] == "Namaste! Great meeting you on the call."

    # User 2 receives and reads messages
    get_msgs = await client.get(f"/api/v1/messages/{fs.id}", headers={"Authorization": f"Bearer {t2}"})
    assert get_msgs.status_code == 200
    assert len(get_msgs.json()) == 1

    # Now User 1 blocks User 2
    block_res = await client.post(
        "/api/v1/moderation/block",
        json={"blocked_id": u2.id, "reason": "Unwanted behavior"},
        headers={"Authorization": f"Bearer {t1}"}
    )
    assert block_res.status_code == 200

    # User 2 tries to send message -> Blocked!
    msg_blocked = await client.post(
        "/api/v1/messages",
        json={"friendship_id": fs.id, "content": "Are you there?"},
        headers={"Authorization": f"Bearer {t2}"}
    )
    assert msg_blocked.status_code == 403

@pytest.mark.asyncio
async def test_report_and_deletion_and_unauthorized_staff(client, db_session):
    u1 = Profile(id=uid(), phone="+919876500009", display_name="Rep1", date_of_birth=date(1995, 1, 1), state_or_union_territory="UP", free_calls_remaining=5, rules_accepted=True)
    u2 = Profile(id=uid(), phone="+919876500010", display_name="Rep2", date_of_birth=date(1996, 1, 1), state_or_union_territory="MP", free_calls_remaining=5, rules_accepted=True)
    db_session.add_all([u1, u2])
    await db_session.commit()

    t1 = create_access_token({"sub": u1.id})

    # File report
    rep = await client.post(
        "/api/v1/moderation/report",
        json={"reported_id": u2.id, "reason": "harassment", "details": "Repeated inappropriate remarks"},
        headers={"Authorization": f"Bearer {t1}"}
    )
    assert rep.status_code == 200
    assert rep.json()["report_id"] is not None

    # Normal user token cannot access /api/v1/admin/reports
    unauth = await client.get("/api/v1/admin/reports", headers={"Authorization": f"Bearer {t1}"})
    assert unauth.status_code in [401, 403]

    # Authorized moderator token CAN access reports
    mod_token = create_staff_token(uid(), "mod_user", "moderator", mfa_verified=True)
    auth_reports = await client.get("/api/v1/admin/reports", headers={"Authorization": f"Bearer {mod_token}"})
    assert auth_reports.status_code == 200
    assert len(auth_reports.json()) >= 1

    # Account deletion flow
    del_res = await client.post("/api/v1/moderation/delete-account", headers={"Authorization": f"Bearer {t1}"})
    assert del_res.status_code == 200
    await db_session.refresh(u1)
    assert u1.is_deleted is True

@pytest.mark.asyncio
async def test_passes_billing_and_expiry_and_refunds(client, db_session):
    user = Profile(id=uid(), phone="+919876500011", display_name="PassUser", date_of_birth=date(1995, 1, 1), state_or_union_territory="Kerala", free_calls_remaining=0, rules_accepted=True)
    db_session.add(user)
    await db_session.commit()

    t = create_access_token({"sub": user.id})

    # Initially has 0 credits and no pass
    p_status = await client.get("/api/v1/passes/status", headers={"Authorization": f"Bearer {t}"})
    assert p_status.json() is None

    # Verify Google Play purchase token
    purchase_tok = "demo_token_gplay_xyz_123"
    buy = await client.post(
        "/api/v1/passes/verify",
        json={"purchase_token": purchase_tok, "order_id": "GPA.1234-5678-9012"},
        headers={"Authorization": f"Bearer {t}"}
    )
    assert buy.status_code == 200
    assert buy.json()["is_active"] is True
    assert buy.json()["remaining_minutes"] in [19, 20]

    # Retrying same token grants at most one pass (idempotent)
    buy_dup = await client.post(
        "/api/v1/passes/verify",
        json={"purchase_token": purchase_tok},
        headers={"Authorization": f"Bearer {t}"}
    )
    assert buy_dup.status_code == 200

    # Admin refunds purchase -> Access revoked
    admin_token = create_staff_token(uid(), "admin", "admin", mfa_verified=True)
    ref = await client.post(f"/api/v1/admin/refund/{purchase_tok}", headers={"Authorization": f"Bearer {admin_token}"})
    assert ref.status_code == 200

    # User pass status is now inactive/none
    p_status2 = await client.get("/api/v1/passes/status", headers={"Authorization": f"Bearer {t}"})
    assert p_status2.json() is None

@pytest.mark.asyncio
async def test_razorpay_order_and_verification_and_language_updates(client, db_session):
    u = Profile(
        id=uid(),
        phone="+919876500012",
        display_name="RazorUser",
        date_of_birth=date(1994, 5, 10),
        state_or_union_territory="Gujarat",
        free_calls_remaining=0,
        rules_accepted=True
    )
    db_session.add(u)
    await db_session.commit()

    token = create_access_token({"sub": u.id})
    auth_header = {"Authorization": f"Bearer {token}"}

    # 1. Test Language Add, Remove, and Selection
    # Initial setup
    update_res = await client.put(
        "/api/v1/auth/languages",
        json={"languages": ["Hindi", "Gujarati", "English"]},
        headers=auth_header
    )
    assert update_res.status_code == 200
    assert set(update_res.json()["languages"]) == {"Hindi", "Gujarati", "English"}

    # Remove Gujarati, add Marathi
    update_res2 = await client.put(
        "/api/v1/auth/languages",
        json={"languages": ["Hindi", "Marathi"]},
        headers=auth_header
    )
    assert update_res2.status_code == 200
    assert set(update_res2.json()["languages"]) == {"Hindi", "Marathi"}

    # 2. Test Razorpay Order Creation
    order_res = await client.post("/api/v1/passes/razorpay/create-order", headers=auth_header)
    assert order_res.status_code == 200
    order_data = order_res.json()
    assert "order_id" in order_data
    assert order_data["amount"] == 2000
    assert order_data["currency"] == "INR"

    # 3. Test Razorpay Payment Verification (Activates 20-minute pass)
    order_id = order_data["order_id"]
    payment_id = f"pay_{uid()[:12]}"
    signature = f"demo_sig_rzp_{uid()[:12]}"

    verify_res = await client.post(
        "/api/v1/passes/razorpay/verify-payment",
        json={
            "razorpay_order_id": order_id,
            "razorpay_payment_id": payment_id,
            "razorpay_signature": signature
        },
        headers=auth_header
    )
    assert verify_res.status_code == 200
    pass_data = verify_res.json()
    assert pass_data["is_active"] is True
    assert pass_data["remaining_minutes"] in [19, 20]

    # Verify pass status endpoint returns active 20-min pass
    status_res = await client.get("/api/v1/passes/status", headers=auth_header)
    assert status_res.status_code == 200
    assert status_res.json()["is_active"] is True
    assert status_res.json()["remaining_minutes"] in [19, 20]

@pytest.mark.asyncio
async def test_feedback_reflects_in_admin(client, db_session):
    u = Profile(
        id=uid(),
        phone="+919876500013",
        display_name="FeedbackUser",
        date_of_birth=date(1996, 3, 20),
        state_or_union_territory="Delhi",
        free_calls_remaining=5,
        rules_accepted=True
    )
    db_session.add(u)
    await db_session.commit()

    token = create_access_token({"sub": u.id})

    # 1. User sends feedback in app
    feed_res = await client.post(
        "/api/v1/moderation/support",
        json={"subject": "Voice Quality", "message": "The 60s voice quality was crystal clear!"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert feed_res.status_code == 200
    ticket_id = feed_res.json()["ticket_id"]
    assert ticket_id is not None

    # 2. Staff/Moderator opens Admin Console and views feedback
    mod_token = create_staff_token(uid(), "mod_agent", "moderator", mfa_verified=True)
    admin_feed_res = await client.get(
        "/api/v1/admin/feedback",
        headers={"Authorization": f"Bearer {mod_token}"}
    )
    assert admin_feed_res.status_code == 200
    feedbacks = admin_feed_res.json()
    assert len(feedbacks) >= 1
    found = any(f["id"] == ticket_id and f["user_display_name"] == "FeedbackUser" for f in feedbacks)
    assert found is True

    # 3. Staff resolves feedback
    resolve_res = await client.post(
        f"/api/v1/admin/feedback/{ticket_id}/resolve",
        headers={"Authorization": f"Bearer {mod_token}"}
    )
    assert resolve_res.status_code == 200
