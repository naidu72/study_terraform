from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Inventory Manager API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str = "postgresql://inventory_user:inventory_pass@localhost:5432/inventory_db"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_CACHE_TTL: int = 300  # 5 minutes
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Stock Alert Threshold
    LOW_STOCK_THRESHOLD: int = 10
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
