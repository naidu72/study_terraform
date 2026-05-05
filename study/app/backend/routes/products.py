from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models import Product, Category, User
from schemas import ProductCreate, ProductResponse, ProductUpdate
from auth import get_current_user, get_current_active_manager
from cache import CacheService
import json

router = APIRouter()


@router.get("/", response_model=List[ProductResponse])
def list_products(
    skip: int = 0,
    limit: int = 100,
    category_id: int = None,
    search: str = None,
    low_stock: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all products with optional filters"""
    query = db.query(Product)
    
    if category_id:
        query = query.filter(Product.category_id == category_id)
    
    if search:
        query = query.filter(
            (Product.name.ilike(f"%{search}%")) | 
            (Product.sku.ilike(f"%{search}%"))
        )
    
    if low_stock:
        query = query.filter(Product.current_stock <= Product.min_stock_level)
    
    products = query.offset(skip).limit(limit).all()
    return products


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get product by ID"""
    # Try to get from cache first
    cache_key = f"product:{product_id}"
    cached = CacheService.get(cache_key)
    
    if cached:
        return cached
    
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Cache the product
    product_dict = {
        "id": product.id,
        "sku": product.sku,
        "name": product.name,
        "description": product.description,
        "category_id": product.category_id,
        "unit_price": product.unit_price,
        "current_stock": product.current_stock,
        "min_stock_level": product.min_stock_level,
        "created_at": product.created_at.isoformat(),
        "updated_at": product.updated_at.isoformat()
    }
    CacheService.set(cache_key, product_dict)
    
    return product


@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_manager)
):
    """Create a new product (manager/admin only)"""
    # Check if SKU exists
    if db.query(Product).filter(Product.sku == product.sku).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="SKU already exists"
        )
    
    # Check if category exists
    category = db.query(Category).filter(Category.id == product.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    db_product = Product(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    
    # Invalidate cache
    CacheService.invalidate_product_cache(db_product.id)
    
    return db_product


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: int,
    product_update: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_manager)
):
    """Update product (manager/admin only)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check category if being updated
    if product_update.category_id:
        category = db.query(Category).filter(Category.id == product_update.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")
    
    update_data = product_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.commit()
    db.refresh(product)
    
    # Invalidate cache
    CacheService.invalidate_product_cache(product_id)
    
    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_manager)
):
    """Delete product (manager/admin only)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(product)
    db.commit()
    
    # Invalidate cache
    CacheService.invalidate_product_cache(product_id)
    
    return None


@router.get("/low-stock/alerts", response_model=List[ProductResponse])
def get_low_stock_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get products with low stock"""
    # Try cache first
    cached_alerts = CacheService.get_low_stock_alerts()
    if cached_alerts:
        return cached_alerts
    
    # Query low stock products
    products = db.query(Product).filter(
        Product.current_stock <= Product.min_stock_level
    ).all()
    
    # Cache the alerts
    CacheService.set_low_stock_alerts([p.__dict__ for p in products])
    
    return products
