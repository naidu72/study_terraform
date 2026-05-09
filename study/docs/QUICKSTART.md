# Quick Start Guide - Phase 1

## What We've Built So Far

✅ **Complete Backend API** with:
- FastAPI framework
- PostgreSQL database
- Redis caching
- JWT authentication
- Role-based access control (Admin, Manager, Viewer)
- Product & Category management
- Stock movement tracking
- Low stock alerts
- Dashboard statistics
- Audit logging

## Prerequisites

```bash
# Install on Ubuntu/WSL2
sudo apt update
sudo apt install -y docker.io docker-compose python3-pip

# Start Docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

## 🚀 Start the Application

### Step 1: Navigate to project

```bash
cd /home/frontier/terraform/study_terraform/study/app
```

### Step 2: Start all services

```bash
docker-compose up -d
```

This starts:
- **PostgreSQL** on port 5432
- **Redis** on port 6379  
- **Backend API** on port 8000

### Step 3: Initialize the database

```bash
docker exec -it inventory_backend python init_db.py
```

This creates:
- Database tables
- 3 users (admin, manager1, viewer1)
- Sample categories (Electronics, Office Supplies, Furniture)
- Sample products with stock data

### Step 4: Test the API

```bash
# Health check
curl http://localhost:8000/health

# Should return:
# {
#   "status": "healthy",
#   "app": "Inventory Manager API",
#   "version": "1.0.0",
#   "redis": "connected"
# }

# API Documentation
open http://localhost:8000/docs
```

## 🔐 Login and Get Token

### Using curl:

```bash
# Login
TOKEN=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" \
  | jq -r '.access_token')

echo $TOKEN
```

### Using the Swagger UI:

1. Go to http://localhost:8000/docs
2. Click "Authorize" button (lock icon)
3. In the username field: `admin`
4. In the password field: `admin123`
5. Click "Authorize"
6. Now you can test all endpoints!

## 📋 Test API Endpoints

### Get current user info

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/auth/me
```

### List all categories

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/categories/
```

### List all products

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/products/
```

### Get dashboard stats

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/dashboard/stats
```

### Get low stock alerts

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/dashboard/low-stock
```

### Create a new product

```bash
curl -X POST "http://localhost:8000/api/v1/products/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "TEST-001",
    "name": "Test Product",
    "description": "A test product",
    "category_id": 1,
    "unit_price": 99.99,
    "current_stock": 100,
    "min_stock_level": 10
  }'
```

### Record a stock movement

```bash
curl -X POST "http://localhost:8000/api/v1/stock/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "movement_type": "out",
    "quantity": 5,
    "reference": "SO-2024-001",
    "notes": "Sales order"
  }'
```

## 👥 User Credentials

| Username | Password | Role | Permissions |
|----------|----------|------|-------------|
| `admin` | `admin123` | Admin | Full access - manage users, products, stock |
| `manager1` | `manager123` | Manager | Manage products and stock movements |
| `viewer1` | `viewer123` | Viewer | Read-only access to all data |

## 🔍 View Logs

```bash
# Backend logs
docker logs -f inventory_backend

# PostgreSQL logs
docker logs -f inventory_postgres

# Redis logs
docker logs -f inventory_redis

# All logs
docker-compose logs -f
```

## 🛑 Stop the Application

```bash
docker-compose down

# To also remove volumes (⚠️ deletes all data):
docker-compose down -v
```

## 📊 Database Access

### Connect to PostgreSQL

```bash
docker exec -it inventory_postgres psql -U inventory_user -d inventory_db

# List tables
\dt

# View users
SELECT id, username, email, role FROM users;

# View products
SELECT id, sku, name, current_stock FROM products;

# View stock movements
SELECT * FROM stock_movements;

# Exit
\q
```

### Connect to Redis

```bash
docker exec -it inventory_redis redis-cli

# View cached keys
KEYS *

# Get a cached value
GET "low_stock_alerts"

# Exit
exit
```

## 🧪 Testing Workflow

### Test as Admin:

1. Login as `admin`
2. Create a new user
3. Create a category
4. Create a product
5. Record stock movement
6. View dashboard stats

### Test as Manager:

1. Login as `manager1`
2. Try to create a user (should fail - admin only)
3. Create a product (should work)
4. Record stock movement (should work)
5. View low stock alerts (should work)

### Test as Viewer:

1. Login as `viewer1`
2. Try to create a product (should fail - read-only)
3. View products (should work)
4. View dashboard (should work)

## 🐛 Troubleshooting

### Backend won't start:

```bash
# Check if PostgreSQL is healthy
docker-compose ps

# View backend logs
docker logs inventory_backend

# Restart backend
docker-compose restart backend
```

### Database connection failed:

```bash
# Check PostgreSQL is running
docker exec -it inventory_postgres pg_isready -U inventory_user

# Check credentials in docker-compose.yml
# DATABASE_URL should match POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
```

### Redis connection failed:

```bash
# Check Redis is running
docker exec -it inventory_redis redis-cli ping
# Should return: PONG
```

### Port already in use:

```bash
# Check what's using port 8000
sudo lsof -i :8000

# Or change the port in docker-compose.yml:
# ports:
#   - "8001:8000"
```

## ✅ Verification Checklist

- [ ] All 3 containers are running (`docker-compose ps`)
- [ ] Backend health check passes (`curl localhost:8000/health`)
- [ ] Can login and get JWT token
- [ ] Can view API documentation at `/docs`
- [ ] Database has sample data (users, categories, products)
- [ ] Can create, read, update, delete products
- [ ] Can record stock movements
- [ ] Low stock alerts appear for products below threshold
- [ ] Dashboard shows correct statistics
- [ ] Role-based access control works (admin vs manager vs viewer)

## 🎯 Next Steps

Once Phase 1 is fully tested and working:

1. **Phase 2**: Build multi-arch Docker images
2. **Phase 3**: Create Terraform modules
3. **Phase 4**: Integrate Vault secrets
4. **Phase 5**: Set up GitHub Actions CI/CD
5. **Phase 6**: Deploy via ArgoCD

---

**Need help? Check the logs or refer to the full documentation in README.md**
