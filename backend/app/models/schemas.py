from pydantic import BaseModel, Field, field_validator
from typing import List, Optional
from datetime import datetime, date
import re

PHONE_REGEX = re.compile(
    r'(?:\+?91[\s.-]?)?[6-9]\d{2}[\s.-]?\d{3}[\s.-]?\d{4}|\b\d{10}\b|\b\d{3}[\s.-]\d{3}[\s.-]\d{4}\b'
)

def validate_no_phone_numbers(text: Optional[str]) -> Optional[str]:
    if not text:
        return text
    if PHONE_REGEX.search(text):
        raise ValueError("For your privacy and safety, phone numbers cannot be shared in your profile description.")
    digits = re.sub(r'\D', '', text)
    if len(digits) >= 10:
        raise ValueError("For your privacy and safety, phone numbers cannot be shared in your profile description.")
    return text

# --- Auth & Profile Schemas ---
class SendOtpRequest(BaseModel):
    phone: str = Field(..., description="Indian phone number with +91 or 10 digits")

    @field_validator("phone")
    def validate_indian_phone(cls, v):
        clean = v.strip().replace(" ", "").replace("-", "")
        if clean.startswith("+91"):
            clean = clean[3:]
        elif clean.startswith("91") and len(clean) == 12:
            clean = clean[2:]
        if not (len(clean) == 10 and clean.isdigit()):
            raise ValueError("Must be a valid 10-digit Indian mobile number")
        return f"+91{clean}"

class SendOtpResponse(BaseModel):
    success: bool
    phone: str
    message: str
    demo_otp: Optional[str] = None # Returned in demo mode for instant testing

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str

class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    is_new_user: bool
    profile_complete: bool

class ProfileCreateRequest(BaseModel):
    display_name: str = Field(..., min_length=2, max_length=50)
    date_of_birth: date
    gender: Optional[str] = Field("Prefer not to say") # Male, Female, Other, Prefer not to say
    looking_for: Optional[str] = Field(None, max_length=500)
    images: Optional[List[str]] = Field(default_factory=list, max_length=3)
    state_or_union_territory: str = Field(..., min_length=2, max_length=50)
    city: Optional[str] = Field(None, max_length=50)
    languages: List[str] = Field(..., min_length=1)
    rules_accepted: bool = Field(True)

    @field_validator("looking_for")
    def check_phone_in_looking_for(cls, v):
        return validate_no_phone_numbers(v)

    @field_validator("date_of_birth")
    def validate_adult(cls, v):
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        if age < 18:
            raise ValueError("FriendLoop is strictly an 18+ community. You must be at least 18 years old to join FriendLoop.")
        return v

class ProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, min_length=2, max_length=50)
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None # Male, Female, Other, Prefer not to say
    looking_for: Optional[str] = Field(None, max_length=500)
    images: Optional[List[str]] = Field(None, max_length=3)
    state_or_union_territory: Optional[str] = None
    city: Optional[str] = None
    languages: Optional[List[str]] = None

    @field_validator("looking_for")
    def check_phone_in_looking_for(cls, v):
        return validate_no_phone_numbers(v)

    @field_validator("date_of_birth")
    def validate_adult(cls, v):
        if v:
            today = date.today()
            age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
            if age < 18:
                raise ValueError("FriendLoop is strictly an 18+ community. You must be at least 18 years old to join FriendLoop.")
        return v

class ImageUploadRequest(BaseModel):
    image_base64: str # Base64 encoded image or data URL
    slot_index: int = 0 # 0, 1, or 2 (up to 3 images)

class ImageUploadResponse(BaseModel):
    success: bool
    image_url: str
    slot_index: int
    images: List[str]

class ProfileResponse(BaseModel):
    id: str
    phone: Optional[str] = None
    display_name: str
    date_of_birth: Optional[date] = None
    age: int = 18
    gender: Optional[str] = "Prefer not to say"
    looking_for: Optional[str] = None
    images: List[str] = Field(default_factory=list)
    state_or_union_territory: str
    city: Optional[str]
    languages: List[str]
    free_calls_remaining: int
    coins: int = 120
    is_plus_subscriber: bool = False
    plus_valid_until: Optional[datetime] = None
    username: Optional[str] = None
    is_adult: bool
    rules_accepted: bool
    has_active_pass: bool = False
    pass_expires_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class FriendProfileResponse(BaseModel):
    id: str
    display_name: str
    age: int = 18
    gender: Optional[str] = "Prefer not to say"
    looking_for: Optional[str] = None
    images: List[str] = Field(default_factory=list)
    state_or_union_territory: str
    city: Optional[str]
    languages: List[str]
    friendship_id: Optional[str] = None
    created_at: datetime

class PublicProfileResponse(BaseModel):
    id: str
    display_name: str
    age: int = 18
    gender: Optional[str] = "Prefer not to say"
    looking_for: Optional[str] = None
    images: List[str] = Field(default_factory=list)
    state_or_union_territory: str
    city: Optional[str]
    languages: List[str]

class UpdateLanguagesRequest(BaseModel):
    languages: List[str] = Field(..., min_items=1)

# --- Match & Call Schemas ---
class JoinQueueRequest(BaseModel):
    call_mode: str = Field(default="voice") # 'voice' or 'video'
    allow_any_language: bool = Field(default=False)

class QueueStatusResponse(BaseModel):
    in_queue: bool
    queue_id: Optional[str] = None
    call_mode: Optional[str] = None
    wait_time_seconds: Optional[int] = None
    allow_any_language: bool = False
    matched_session: Optional["CallSessionResponse"] = None

class CallSessionResponse(BaseModel):
    id: str
    room_id: str
    call_mode: str
    status: str
    started_at: Optional[datetime]
    shared_end_time: Optional[datetime]
    duration_seconds: int = 60
    token: Optional[str] = None
    partner: Optional[PublicProfileResponse] = None

class ConnectCallRequest(BaseModel):
    room_id: str

class ReconnectResponse(BaseModel):
    room_id: str
    status: str
    shared_end_time: Optional[datetime]
    remaining_seconds: int

class ProviderWebhookEvent(BaseModel):
    event: str # 'participant_joined', 'participant_left', 'room_finished'
    room_id: str
    user_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# --- Friendship & Messages ---
class FriendChoiceRequest(BaseModel):
    call_id: str
    target_id: str

class FriendChoiceResponse(BaseModel):
    choice_recorded: bool
    is_mutual: bool
    friendship_id: Optional[str] = None

class FriendListItem(BaseModel):
    friendship_id: str
    friend_id: str
    display_name: str
    age: int = 18
    gender: Optional[str] = "Prefer not to say"
    images: List[str] = Field(default_factory=list)
    state_or_union_territory: str
    city: Optional[str]
    unread_count: int = 0
    last_message: Optional[str] = None
    last_message_time: Optional[datetime] = None
    created_at: datetime

class SendMessageRequest(BaseModel):
    friendship_id: str
    content: str = Field(..., min_length=1, max_length=5000)
    message_type: Optional[str] = "text"
    media_url: Optional[str] = None

class MessageResponse(BaseModel):
    id: str
    friendship_id: str
    sender_id: str
    content: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class UpdateMessageStatusRequest(BaseModel):
    status: str # delivered, read

# --- Moderation & Support ---
class BlockUserRequest(BaseModel):
    blocked_id: str
    reason: Optional[str] = None

class ReportRequest(BaseModel):
    reported_id: Optional[str] = None
    target_id: Optional[str] = None
    target_type: Optional[str] = None # 'user', 'reel', 'room', 'call', 'message'
    call_id: Optional[str] = None
    reason: str # harassment, threats, scam, underage, inappropriate_content, other
    details: Optional[str] = None

class ReportResponse(BaseModel):
    report_id: str
    message: str

class SupportTicketRequest(BaseModel):
    subject: str
    message: str

class SupportTicketDetail(BaseModel):
    id: str
    user_id: str
    user_display_name: str
    user_phone: str
    subject: str
    message: str
    status: str
    created_at: datetime

# --- Passes & Billing ---
class VerifyPurchaseRequest(BaseModel):
    purchase_token: str
    order_id: Optional[str] = None
    package_name: Optional[str] = None

class RazorpayOrderCreateRequest(BaseModel):
    amount: int = 2000 # 2000 paise = 20 INR
    currency: str = "INR"

class RazorpayOrderResponse(BaseModel):
    order_id: str
    amount: int
    currency: str
    key_id: str
    description: str = "Aara 20-Minute Random Voice Match Pass"

class RazorpayVerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

class PassResponse(BaseModel):
    id: str
    status: str
    starts_at: datetime
    expires_at: datetime
    is_active: bool
    remaining_minutes: int

# --- Staff Admin Schemas ---
class StaffLoginRequest(BaseModel):
    username: str
    password: str

class StaffLoginResponse(BaseModel):
    token: str
    username: str
    role: str
    requires_mfa: bool = False

class MfaVerifyRequest(BaseModel):
    temp_token: str
    otp_code: str

class SuspendUserRequest(BaseModel):
    user_id: str
    reason: str

class StaffReportDetail(BaseModel):
    id: str
    reported_user_id: str
    reported_display_name: str
    reported_phone: str
    reported_dob: date
    reported_is_adult: bool
    reported_is_suspended: bool
    call_id: Optional[str]
    reason: str
    details: Optional[str]
    status: str
    created_at: datetime

class UsageMetricsResponse(BaseModel):
    total_users: int
    queue_wait_average_seconds: float
    connection_success_rate: float
    connected_minutes_voice: float
    connected_minutes_video: float
    fifth_call_completion_count: int
    otp_sends_count: int
    estimated_provider_spend_inr: float

# --- FriendLoop Upgrade Schemas ---
class ReelResponse(BaseModel):
    id: str
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    video_url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    likes_count: int = 0
    comments_count: int = 0
    is_liked: bool = False
    created_at: datetime

class ReelCreateRequest(BaseModel):
    video_url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None

class ReelCommentRequest(BaseModel):
    comment_text: str = Field(..., min_length=1, max_length=500)

class ReelCommentResponse(BaseModel):
    id: str
    reel_id: str
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    comment_text: str
    likes_count: int = 0
    created_at: datetime

class GalleryItemResponse(BaseModel):
    id: str
    user_id: str
    media_type: str = "photo" # photo, video
    media_url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    is_plus_only: bool = True
    created_at: datetime

class GalleryUploadRequest(BaseModel):
    media_type: str = "photo" # photo, video
    media_url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    is_plus_only: bool = True

class PartyRoomCreateRequest(BaseModel):
    title: str = Field(..., min_length=2, max_length=100)
    room_type: str = Field("voice") # voice, video
    activity_type: str = Field("voice_lounge") # ludo, carrom, truth_or_dare, voice_mimic, voice_lounge, video_stage
    language: str = Field("Hindi")
    access_type: str = Field("public") # public, invite_only, vip
    entry_fee_coins: int = Field(0, ge=0)
    max_seats: int = Field(8, ge=2, le=24)

class PartyParticipantResponse(BaseModel):
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    role: str # host, speaker, listener
    seat_index: Optional[int] = None
    joined_at: datetime

class PartyRoomResponse(BaseModel):
    id: str
    title: str
    host_id: str
    host_name: str
    host_avatar: Optional[str] = None
    room_type: str
    activity_type: str
    language: str
    access_type: str
    entry_fee_coins: int
    max_seats: int
    active_count: int
    status: str
    participants: List[PartyParticipantResponse] = Field(default_factory=list)
    created_at: datetime

class CoinPackPurchaseRequest(BaseModel):
    pack_id: str # 'pack_40', 'pack_100', 'pack_275'
    coins: int
    price_inr: float
    payment_method: Optional[str] = "google_play" # "google_play" (Play Billing) or "alternative_razorpay" (User Choice Billing India)

class CoinTransactionResponse(BaseModel):
    id: str
    amount: int
    transaction_type: str
    description: Optional[str] = None
    created_at: datetime

class WalletBalanceResponse(BaseModel):
    coins: int
    transactions: List[CoinTransactionResponse] = Field(default_factory=list)

class PlusSubscriptionResponse(BaseModel):
    is_plus_subscriber: bool
    plus_valid_until: Optional[datetime] = None
    price_inr: float = 350.00
    plan_name: str = "FriendLoop Plus Monthly"

class AdminOverviewStats(BaseModel):
    total_users: int
    active_now: int
    total_reels: int
    total_rooms: int
    total_coin_sales_inr: float
    total_plus_sales_inr: float
    gross_revenue_inr: float
    refunds_inr: float
    expenses_inr: float
    taxes_inr: float
    net_profit_inr: float
    city_distribution: List[dict]
    recent_registrations: List[dict]
    coin_packs_sold: List[dict]

QueueStatusResponse.model_rebuild()
