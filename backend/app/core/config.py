import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator
from typing import Optional

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=(".env", "backend/.env"), extra="allow")
    ENVIRONMENT: str = Field(default="development")
    DEMO_MODE: bool = Field(default=True)
    APP_NAME: str = Field(default="Aara")

    DATABASE_URL: str = Field(default="sqlite+aiosqlite:///./aara.db")

    SUPABASE_URL: str = Field(default="https://demo.supabase.co")
    SUPABASE_KEY: str = Field(default="demo-anon-key")
    SUPABASE_JWT_SECRET: str = Field(default="demo-supabase-jwt-secret-min-32-chars-xyz-123456")

    CALLING_PROVIDER: str = Field(default="demo") # demo | livekit | agora
    CALLING_API_KEY: str = Field(default="demo_call_key")
    CALLING_API_SECRET: str = Field(default="demo_call_secret_change_in_production")
    CALLING_WEBHOOK_SECRET: str = Field(default="demo_webhook_secret")

    # Feature Flags
    FEATURE_PRIVATE_VOICE: bool = Field(default=False)
    FEATURE_VIDEO: bool = Field(default=False)
    FEATURE_PAID_PASS: bool = Field(default=True)

    # Razorpay Payment Gateway
    RAZORPAY_KEY_ID: str = Field(default="rzp_test_aara_pilot")
    RAZORPAY_KEY_SECRET: str = Field(default="rzp_test_secret_aara_pilot")

    GOOGLE_PLAY_PACKAGE_NAME: str = Field(default="com.aara.social")
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: Optional[str] = Field(default=None)

    ADMIN_SECRET_KEY: str = Field(default="admin-super-secret-key-change-in-production-12345")
    ADMIN_DEFAULT_USERNAME: str = Field(default="admin")
    ADMIN_DEFAULT_PASSWORD: str = Field(default="Admin@12345")

    @field_validator("SUPABASE_JWT_SECRET")
    def validate_production_security(cls, v, values):
        # We also enforce strict validation during startup in main.py
        return v

    def validate_production_readiness(self):
        if self.ENVIRONMENT.lower() == "production" or not self.DEMO_MODE:
            if "demo" in self.SUPABASE_JWT_SECRET.lower() or len(self.SUPABASE_JWT_SECRET) < 32:
                raise ValueError("FATAL: Production mode requires a secure SUPABASE_JWT_SECRET (min 32 characters, non-demo).")
            if self.CALLING_PROVIDER == "demo" or "demo" in self.CALLING_API_KEY.lower():
                raise ValueError("FATAL: Production mode requires a live calling provider (not 'demo').")
            if "change-in-production" in self.ADMIN_SECRET_KEY.lower() or len(self.ADMIN_SECRET_KEY) < 24:
                raise ValueError("FATAL: Production mode requires a secure ADMIN_SECRET_KEY.")

settings = Settings()
