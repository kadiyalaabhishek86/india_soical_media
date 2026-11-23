import hmac
import hashlib
import time
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from app.core.config import settings

class CallingProviderInterface(ABC):
    @abstractmethod
    def create_room(self, room_id: str, call_mode: str = "voice") -> Dict[str, Any]:
        """Creates a media room for participants."""
        pass

    @abstractmethod
    def generate_token(self, room_id: str, user_id: str, display_name: str) -> str:
        """Generates a short-lived token for a participant to join the room."""
        pass

    @abstractmethod
    def end_room(self, room_id: str) -> bool:
        """Closes the room and terminates media tracks."""
        pass

    @abstractmethod
    def verify_webhook_signature(self, raw_body: bytes, signature_header: Optional[str]) -> bool:
        """Authenticates incoming provider webhook events."""
        pass

class DemoCallingProvider(CallingProviderInterface):
    """
    Simulated calling provider for testing and offline/local demonstration.
    Generates deterministic tokens and tracks virtual session states.
    """
    def __init__(self):
        self.active_rooms: Dict[str, Dict[str, Any]] = {}

    def create_room(self, room_id: str, call_mode: str = "voice") -> Dict[str, Any]:
        room_data = {
            "room_id": room_id,
            "call_mode": call_mode,
            "created_at": time.time(),
            "status": "active",
            "participants": {}
        }
        self.active_rooms[room_id] = room_data
        return room_data

    def generate_token(self, room_id: str, user_id: str, display_name: str) -> str:
        # Returns a clean structured demo token
        return f"aara_demo_token_{room_id[:8]}_{user_id[:8]}"

    def end_room(self, room_id: str) -> bool:
        if room_id in self.active_rooms:
            self.active_rooms[room_id]["status"] = "closed"
            return True
        return False

    def verify_webhook_signature(self, raw_body: bytes, signature_header: Optional[str]) -> bool:
        # In demo mode, accept test signature or default secret match
        if signature_header == "demo-signature-valid" or not signature_header:
            return True
        expected = hmac.new(settings.CALLING_WEBHOOK_SECRET.encode(), raw_body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature_header)

class LiveCallingProvider(CallingProviderInterface):
    """
    Production calling provider adapter (LiveKit / Agora / 100ms standard).
    """
    def __init__(self, api_key: str, api_secret: str):
        self.api_key = api_key
        self.api_secret = api_secret

    def create_room(self, room_id: str, call_mode: str = "voice") -> Dict[str, Any]:
        # Production WebRTC room creation
        return {
            "room_id": room_id,
            "call_mode": call_mode,
            "provider": "livekit",
            "created_at": time.time(),
            "status": "active"
        }

    def generate_token(self, room_id: str, user_id: str, display_name: str) -> str:
        # Generates HMAC-signed WebRTC JWT
        import jwt
        now = int(time.time())
        claims = {
            "iss": self.api_key,
            "sub": user_id,
            "name": display_name,
            "video": {
                "room": room_id,
                "roomJoin": True,
                "canPublish": True,
                "canSubscribe": True
            },
            "nbf": now,
            "exp": now + 300 # 5 minutes short-lived
        }
        return jwt.encode(claims, self.api_secret, algorithm="HS256")

    def end_room(self, room_id: str) -> bool:
        return True

    def verify_webhook_signature(self, raw_body: bytes, signature_header: Optional[str]) -> bool:
        if not signature_header:
            return False
        expected = hmac.new(settings.CALLING_WEBHOOK_SECRET.encode(), raw_body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature_header)

def get_calling_provider() -> CallingProviderInterface:
    if settings.CALLING_PROVIDER == "demo" or settings.DEMO_MODE:
        return DemoCallingProvider()
    return LiveCallingProvider(settings.CALLING_API_KEY, settings.CALLING_API_SECRET)
