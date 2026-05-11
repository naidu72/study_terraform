import redis
import json
from typing import Optional, Any
from config import settings

redis_client = redis.Redis.from_url(
    settings.REDIS_URL,
    decode_responses=True
)


class CacheService:
    """Redis cache service for sessions and stock alerts"""
    
    @staticmethod
    def set(key: str, value: Any, ttl: int = None) -> bool:
        """Set a value in cache with optional TTL"""
        try:
            if ttl is None:
                ttl = settings.REDIS_CACHE_TTL
            
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            
            redis_client.setex(key, ttl, value)
            return True
        except Exception as e:
            print(f"Cache set error: {e}")
            return False
    
    @staticmethod
    def get(key: str) -> Optional[Any]:
        """Get a value from cache"""
        try:
            value = redis_client.get(key)
            if value:
                try:
                    return json.loads(value)
                except json.JSONDecodeError:
                    return value
            return None
        except Exception as e:
            print(f"Cache get error: {e}")
            return None
    
    @staticmethod
    def delete(key: str) -> bool:
        """Delete a key from cache"""
        try:
            redis_client.delete(key)
            return True
        except Exception as e:
            print(f"Cache delete error: {e}")
            return False
    
    @staticmethod
    def exists(key: str) -> bool:
        """Check if key exists in cache"""
        try:
            return redis_client.exists(key) > 0
        except Exception as e:
            print(f"Cache exists error: {e}")
            return False
    
    @staticmethod
    def get_low_stock_alerts() -> list:
        """Get list of low stock products from cache"""
        return CacheService.get("low_stock_alerts") or []
    
    @staticmethod
    def set_low_stock_alerts(alerts: list) -> bool:
        """Cache low stock alerts"""
        return CacheService.set("low_stock_alerts", alerts, ttl=300)
    
    @staticmethod
    def invalidate_product_cache(product_id: int) -> bool:
        """Invalidate cache for a specific product"""
        keys = [
            f"product:{product_id}",
            "low_stock_alerts",
            "dashboard_stats"
        ]
        for key in keys:
            CacheService.delete(key)
        return True


def check_redis_connection() -> bool:
    """Check if Redis is available"""
    try:
        redis_client.ping()
        return True
    except Exception as e:
        print(f"Redis connection error: {e}")
        return False
