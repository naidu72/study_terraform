#!/usr/bin/env python3
"""Initialize the Inventory Manager database with sample data"""
from database import SessionLocal, engine, Base
from models import User, Category, Product, StockMovement, MovementType
from auth import get_password_hash
import sys

def init_database():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("✓ Database tables created")

def create_users(db):
    print("\nCreating users...")
    users = [
        User(username="admin", email="admin@inventory.local", full_name="System Administrator",
             role="admin", hashed_password=get_password_hash("admin123"), is_active=1),
        User(username="manager1", email="manager@inventory.local", full_name="Inventory Manager",
             role="manager", hashed_password=get_password_hash("manager123"), is_active=1),
        User(username="viewer1", email="viewer@inventory.local", full_name="Inventory Viewer",
             role="viewer", hashed_password=get_password_hash("viewer123"), is_active=1),
    ]
    for user in users:
        if not db.query(User).filter(User.username == user.username).first():
            db.add(user)
            print(f"  ✓ Created user: {user.username} (role: {user.role})")
    db.commit()

def create_categories(db):
    print("\nCreating categories...")
    categories = [
        Category(name="Electronics", description="Electronic devices and accessories"),
        Category(name="Office Supplies", description="Office and stationery items"),
        Category(name="Furniture", description="Office and home furniture"),
    ]
    for category in categories:
        if not db.query(Category).filter(Category.name == category.name).first():
            db.add(category)
            print(f"  ✓ Created category: {category.name}")
    db.commit()

def create_products(db):
    print("\nCreating products...")
    products = [
        Product(sku="ELEC-001", name="Dell Laptop XPS 15", category_id=1, unit_price=1299.99, current_stock=45, min_stock_level=10),
        Product(sku="ELEC-002", name="Logitech Mouse", category_id=1, unit_price=99.99, current_stock=120, min_stock_level=20),
        Product(sku="OFFC-001", name="A4 Paper", category_id=2, unit_price=8.99, current_stock=5, min_stock_level=50),
    ]
    for product in products:
        if not db.query(Product).filter(Product.sku == product.sku).first():
            db.add(product)
            print(f"  ✓ Created product: {product.name}")
    db.commit()

def main():
    print("="*60)
    print("Inventory Manager - Database Initialization")
    print("="*60)
    try:
        init_database()
        db = SessionLocal()
        try:
            create_users(db)
            create_categories(db)
            create_products(db)
            print("\n"+"="*60)
            print("✓ Initialization completed!")
            print("="*60)
            print("\n📋 Credentials: admin/admin123, manager1/manager123, viewer1/viewer123")
        finally:
            db.close()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
