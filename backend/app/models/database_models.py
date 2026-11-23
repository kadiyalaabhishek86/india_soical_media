import uuid
from datetime import datetime, date
from sqlalchemy import (
    Column, String, Boolean, Integer, DateTime, Date, Numeric, Text, ForeignKey, UniqueConstraint, CheckConstraint, Uuid, JSON
)
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    display_name = Column(String(50), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String(20), default="Prefer not to say", nullable=True) # Male, Female, Other, Prefer not to say
    looking_for = Column(Text, nullable=True) # Bio / Looking for (NO phone numbers allowed)
    images = Column(JSON, default=list, nullable=False) # List of up to 3 image URLs/base64 strings
    state_or_union_territory = Column(String(50), nullable=False)
    city = Column(String(50), nullable=True)
    is_suspended = Column(Boolean, default=False, nullable=False)
    suspension_reason = Column(Text, nullable=True)
    free_calls_remaining = Column(Integer, default=5, nullable=False)
    coins = Column(Integer, default=120, nullable=False)
    is_plus_subscriber = Column(Boolean, default=False, nullable=False)
    plus_valid_until = Column(DateTime(timezone=True), nullable=True)
    username = Column(String(50), nullable=True)
    rules_accepted = Column(Boolean, default=False, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    languages = relationship("ProfileLanguage", back_populates="profile", cascade="all, delete-orphan", lazy="selectin")

    @property
    def is_adult(self) -> bool:
        today = date.today()
        age = today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )
        return age >= 18

    @property
    def age(self) -> int:
        if not self.date_of_birth:
            return 18
        today = date.today()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )

class ProfileLanguage(Base):
    __tablename__ = "profile_languages"

    profile_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    language = Column(String(30), primary_key=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    profile = relationship("Profile", back_populates="languages")

class QueueEntry(Base):
    __tablename__ = "queue_entries"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), unique=True, nullable=False)
    call_mode = Column(String(10), default="voice", nullable=False)
    allow_any_language = Column(Boolean, default=False, nullable=False)
    status = Column(String(20), default="waiting", nullable=False) # waiting, matched, cancelled
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

class CallSession(Base):
    __tablename__ = "call_sessions"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    room_id = Column(String(100), unique=True, nullable=False, index=True)
    call_mode = Column(String(10), default="voice", nullable=False)
    status = Column(String(20), default="created", nullable=False) # created, connecting, connected, completed, cancelled, terminated
    started_at = Column(DateTime(timezone=True), nullable=True)
    shared_end_time = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Integer, default=60, nullable=False)
    terminated_reason = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    participants = relationship("CallParticipant", back_populates="session", cascade="all, delete-orphan", lazy="selectin")

class CallParticipant(Base):
    __tablename__ = "call_participants"

    call_id = Column(Uuid(as_uuid=False), ForeignKey("call_sessions.id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    role = Column(String(20), default="participant", nullable=False)
    token = Column(Text, nullable=True)
    connected_at = Column(DateTime(timezone=True), nullable=True)
    disconnected_at = Column(DateTime(timezone=True), nullable=True)

    session = relationship("CallSession", back_populates="participants")

class CallUsageRecord(Base):
    __tablename__ = "call_usage_records"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    call_id = Column(Uuid(as_uuid=False), ForeignKey("call_sessions.id", ondelete="CASCADE"), nullable=False)
    credit_type = Column(String(20), default="free", nullable=False) # free, paid_pass
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "call_id", name="uq_user_call_usage"),
    )

class FriendChoice(Base):
    __tablename__ = "friend_choices"

    call_id = Column(Uuid(as_uuid=False), ForeignKey("call_sessions.id", ondelete="CASCADE"), primary_key=True)
    chooser_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    target_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id1 = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    user_id2 = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(20), default="active", nullable=False) # active, unfriended, blocked
    origin_call_id = Column(Uuid(as_uuid=False), ForeignKey("call_sessions.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id1", "user_id2", name="uq_friendship_pair"),
    )

class Message(Base):
    __tablename__ = "messages"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    friendship_id = Column(Uuid(as_uuid=False), ForeignKey("friendships.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    status = Column(String(20), default="sent", nullable=False) # sent, delivered, read
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Block(Base):
    __tablename__ = "blocks"

    blocker_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    blocked_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Report(Base):
    __tablename__ = "reports"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    reporter_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    reported_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    call_id = Column(Uuid(as_uuid=False), ForeignKey("call_sessions.id", ondelete="SET NULL"), nullable=True)
    reason = Column(String(30), nullable=False)
    details = Column(Text, nullable=True)
    status = Column(String(20), default="pending", nullable=False) # pending, investigating, resolved, dismissed
    reviewed_by = Column(Uuid(as_uuid=False), nullable=True)
    resolution_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    subject = Column(String(200), default="Feedback & Support", nullable=False)
    message = Column(Text, nullable=False)
    status = Column(String(20), default="open", nullable=False) # open, in_progress, resolved
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Pass(Base):
    __tablename__ = "passes"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    purchase_token = Column(String(255), unique=True, nullable=False)
    order_id = Column(String(100), nullable=True)
    price_inr = Column(Numeric(10, 2), default=20.00, nullable=False)
    duration_minutes = Column(Integer, default=20, nullable=False)
    starts_at = Column(DateTime(timezone=True), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(20), default="active", nullable=False) # pending, active, expired, refunded
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class StaffUser(Base):
    __tablename__ = "staff_users"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    mfa_secret = Column(String(64), nullable=True)
    role = Column(String(20), default="moderator", nullable=False) # admin, moderator, operator
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class StaffAuditLog(Base):
    __tablename__ = "staff_audit_logs"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    staff_id = Column(Uuid(as_uuid=False), nullable=True)
    staff_username = Column(String(50), nullable=False)
    action = Column(String(100), nullable=False)
    target_id = Column(String(100), nullable=True)
    reason = Column(Text, nullable=True)
    metadata_json = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Reel(Base):
    __tablename__ = "reels"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    video_url = Column(Text, nullable=False)
    thumbnail_url = Column(Text, nullable=True)
    caption = Column(Text, nullable=True)
    likes_count = Column(Integer, default=0, nullable=False)
    comments_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    user = relationship("Profile", lazy="selectin")

class ReelLike(Base):
    __tablename__ = "reel_likes"

    reel_id = Column(Uuid(as_uuid=False), ForeignKey("reels.id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class ReelComment(Base):
    __tablename__ = "reel_comments"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    reel_id = Column(Uuid(as_uuid=False), ForeignKey("reels.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    comment_text = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    user = relationship("Profile", lazy="selectin")

class GalleryItem(Base):
    __tablename__ = "galleries"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    media_type = Column(String(20), default="photo", nullable=False) # photo, video
    media_url = Column(Text, nullable=False)
    thumbnail_url = Column(Text, nullable=True)
    caption = Column(Text, nullable=True)
    is_plus_only = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class PartyRoom(Base):
    __tablename__ = "party_rooms"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    title = Column(String(120), nullable=False)
    host_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    room_type = Column(String(20), default="voice", nullable=False) # voice, video
    activity_type = Column(String(30), default="voice_lounge", nullable=False) # ludo, carrom, truth_or_dare, voice_mimic, voice_lounge, video_stage
    language = Column(String(40), default="Hindi", nullable=False)
    access_type = Column(String(20), default="public", nullable=False) # public, invite_only, vip
    entry_fee_coins = Column(Integer, default=0, nullable=False)
    max_seats = Column(Integer, default=8, nullable=False)
    status = Column(String(20), default="active", nullable=False) # active, closed
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    host = relationship("Profile", foreign_keys=[host_id], lazy="selectin")
    participants = relationship("PartyParticipant", back_populates="room", cascade="all, delete-orphan", lazy="selectin")

class PartyParticipant(Base):
    __tablename__ = "party_participants"

    room_id = Column(Uuid(as_uuid=False), ForeignKey("party_rooms.id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    role = Column(String(20), default="listener", nullable=False) # host, speaker, listener
    seat_index = Column(Integer, nullable=True)
    joined_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    room = relationship("PartyRoom", back_populates="participants")
    user = relationship("Profile", lazy="selectin")

class CoinTransaction(Base):
    __tablename__ = "coin_transactions"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    transaction_type = Column(String(40), nullable=False) # purchase, call_voice, call_video, room_entry, gift, bonus
    description = Column(Text, nullable=True)
    reference_id = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    user_id = Column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    plan_id = Column(String(40), default="plus_monthly", nullable=False)
    price_inr = Column(Numeric(10, 2), default=350.00, nullable=False)
    status = Column(String(20), default="active", nullable=False) # active, expired, cancelled
    starts_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class AdminExpense(Base):
    __tablename__ = "admin_expenses"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    category = Column(String(60), nullable=False)
    amount_inr = Column(Numeric(12, 2), nullable=False)
    description = Column(Text, nullable=True)
    recorded_by = Column(Uuid(as_uuid=False), ForeignKey("staff_users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class AdminTax(Base):
    __tablename__ = "admin_taxes"

    id = Column(Uuid(as_uuid=False), primary_key=True, default=generate_uuid)
    tax_type = Column(String(40), nullable=False)
    rate_percentage = Column(Numeric(5, 2), default=18.00, nullable=False)
    amount_inr = Column(Numeric(12, 2), nullable=False)
    period = Column(String(30), nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

