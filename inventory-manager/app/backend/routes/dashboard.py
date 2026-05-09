from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models import Product, Category, StockMovement, User
from schemas import DashboardStats, LowStockAlert
from auth import get_current_user
from cache import CacheService
from typing import List

router = APIRouter()


@router.get("/stats", response_model=DashboardStats)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get dashboard statistics"""
    cached = CacheService.get("dashboard_stats")
    if cached:
        return cached
    
    total_products = db.query(func.count(Product.id)).scalar()
    total_categories = db.query(func.count(Category.id)).scalar()
    low_stock_items = db.query(func.count(Product.id)).filter(
        Product.current_stock <= Product.min_stock_level
    ).scalar()
    
    total_value = db.query(
        func.sum(Product.current_stock * Product.unit_price)
    ).scalar() or 0.0
    
    recent_movements = db.query(func.count(StockMovement.id)).filter(
        StockMovement.created_at >= func.current_date()
    ).scalar()
    
    stats = {
        "total_products": total_products,
        "total_categories": total_categories,
        "low_stock_items": low_stock_items,
        "total_stock_value": float(total_value),
        "recent_movements": recent_movements
    }
    
    CacheService.set("dashboard_stats", stats, ttl=60)
    return stats


@router.get("/low-stock", response_model=List[LowStockAlert])
def get_low_stock_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get low stock alerts"""
    products = db.query(Product).filter(
        Product.current_stock <= Product.min_stock_level
    ).all()
    
    alerts = [
        {
            "product_id": p.id,
            "sku": p.sku,
            "name": p.name,
            "current_stock": p.current_stock,
            "min_stock_level": p.min_stock_level
        }
        for p in products
    ]
    
    return alerts
