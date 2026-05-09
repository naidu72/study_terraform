from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List
from database import get_db
from models import StockMovement, Product, User, MovementType
from schemas import StockMovementCreate, StockMovementResponse
from auth import get_current_user, get_current_active_manager
from cache import CacheService
import json

router = APIRouter()


@router.get("/", response_model=List[StockMovementResponse])
def list_movements(
    skip: int = 0,
    limit: int = 100,
    product_id: int = None,
    movement_type: MovementType = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List stock movements with optional filters"""
    query = db.query(StockMovement)
    
    if product_id:
        query = query.filter(StockMovement.product_id == product_id)
    
    if movement_type:
        query = query.filter(StockMovement.movement_type == movement_type)
    
    movements = query.order_by(desc(StockMovement.created_at)).offset(skip).limit(limit).all()
    return movements


@router.get("/{movement_id}", response_model=StockMovementResponse)
def get_movement(
    movement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get stock movement by ID"""
    movement = db.query(StockMovement).filter(StockMovement.id == movement_id).first()
    if not movement:
        raise HTTPException(status_code=404, detail="Stock movement not found")
    return movement


@router.post("/", response_model=StockMovementResponse, status_code=status.HTTP_201_CREATED)
def create_movement(
    movement: StockMovementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_manager)
):
    """Create a stock movement (manager/admin only)"""
    product = db.query(Product).filter(Product.id == movement.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    if movement.movement_type == MovementType.IN:
        new_stock = product.current_stock + movement.quantity
    elif movement.movement_type == MovementType.OUT:
        new_stock = product.current_stock - movement.quantity
        if new_stock < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient stock"
            )
    else:
        new_stock = movement.quantity
    
    db_movement = StockMovement(**movement.dict(), created_by=current_user.id)
    db.add(db_movement)
    product.current_stock = new_stock
    db.commit()
    db.refresh(db_movement)
    
    CacheService.invalidate_product_cache(product.id)
    if product.current_stock <= product.min_stock_level:
        CacheService.delete("low_stock_alerts")
    
    return db_movement
