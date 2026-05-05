# Inventory Manager - Enterprise Application

A full-featured inventory management system built with FastAPI, PostgreSQL, Redis, and React. Designed for enterprise use with proper authentication, role-based access control, audit logging, and real-time stock alerts.

## Architecture

```
Frontend (React + Nginx)
        ↓
Backend API (FastAPI)
    ↓         ↓
PostgreSQL  Redis
```

## Features

- **User Management**: Admin, Manager, and Viewer roles
- **Product Catalog**: Categories and products with SKU tracking
- **Stock Management**: Track IN/OUT/ADJUSTMENT movements
- **Low Stock Alerts**: Cached in Redis for performance
- **Audit Logging**: Track who changed what and when
- **JWT Authentication**: Secure token-based auth
- **Role-Based Access Control**: Different permissions per role

## Tech Stack

### Backend
- **FastAPI**: Modern async Python web framework
- **SQLAlchemy**: ORM for PostgreSQL
- **PostgreSQL**: Relational database
- **Redis**: Caching and session management
- **JWT**: Authentication tokens
- **Pydantic**: Data validation

### Infrastructure
- **Docker**: Containerization
- **Kubernetes**: Orchestration (Pi cluster)
- **Terraform**: Infrastructure as Code
- **ArgoCD**: GitOps deployment
- **Vault**: Secrets management
- **cert-manager**: TLS certificates
- **Cloudflare Tunnel**: Public exposure

## Prerequisites

- Python 3.11+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

## Quick Start (Local Development)

### 1. Clone the repository

```bash
cd /home/frontier/terraform/study_terraform/study
```

### 2. Start services with Docker Compose

```bash
cd app
docker-compose up -d
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379
- Backend API on port 8000

### 3. Access the API

- API Docs: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- Root: http://localhost:8000/

### 4. Create initial admin user

```bash
# Connect to the backend container
docker exec -it inventory_backend python

# In Python shell:
from database import SessionLocal, engine
from models import Base, User
from auth import get_password_hash

# Create tables
Base.metadata.create_all(bind=engine)

# Create admin user
db = SessionLocal()
admin = User(
    username="admin",
    email="admin@inventory.local",
    full_name="System Administrator",
    role="admin",
    hashed_password=get_password_hash("admin123"),
    is_active=1
)
db.add(admin)
db.commit()
print("Admin user created!")
```

### 5. Test the API

```bash
# Login to get token
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# Use the token for authenticated requests
TOKEN="<your-access-token>"

# Get current user info
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/auth/me"

# Create a category
curl -X POST "http://localhost:8000/api/v1/categories/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Electronics", "description": "Electronic items"}'

# Create a product
curl -X POST "http://localhost:8000/api/v1/products/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "PROD-001",
    "name": "Laptop Dell XPS 15",
    "description": "High-performance laptop",
    "category_id": 1,
    "unit_price": 1299.99,
    "current_stock": 50,
    "min_stock_level": 10
  }'
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user (admin only)
- `POST /api/v1/auth/login` - Login and get JWT token
- `GET /api/v1/auth/me` - Get current user info
- `GET /api/v1/auth/users` - List all users (admin only)

### Categories
- `GET /api/v1/categories/` - List categories
- `POST /api/v1/categories/` - Create category (manager/admin)
- `GET /api/v1/categories/{id}` - Get category by ID
- `PUT /api/v1/categories/{id}` - Update category (manager/admin)
- `DELETE /api/v1/categories/{id}` - Delete category (manager/admin)

### Products
- `GET /api/v1/products/` - List products (with filters)
- `POST /api/v1/products/` - Create product (manager/admin)
- `GET /api/v1/products/{id}` - Get product by ID
- `PUT /api/v1/products/{id}` - Update product (manager/admin)
- `DELETE /api/v1/products/{id}` - Delete product (manager/admin)
- `GET /api/v1/products/low-stock/alerts` - Get low stock alerts

### Stock Movements
- `GET /api/v1/stock/` - List stock movements
- `POST /api/v1/stock/` - Create stock movement (manager/admin)
- `GET /api/v1/stock/{id}` - Get movement by ID
- `GET /api/v1/stock/product/{id}/history` - Get product movement history

### Dashboard
- `GET /api/v1/dashboard/stats` - Get dashboard statistics
- `GET /api/v1/dashboard/low-stock` - Get low stock alerts

## User Roles

| Role | Permissions |
|------|------------|
| **Admin** | Full access - manage users, categories, products, stock |
| **Manager** | Manage categories, products, and stock movements |
| **Viewer** | Read-only access to all data |

## Database Schema

```sql
users
├── id (PK)
├── username (unique)
├── email (unique)
├── hashed_password
├── full_name
├── role (admin/manager/viewer)
├── is_active
└── timestamps

categories
├── id (PK)
├── name (unique)
├── description
└── timestamps

products
├── id (PK)
├── sku (unique)
├── name
├── description
├── category_id (FK)
├── unit_price
├── current_stock
├── min_stock_level
└── timestamps

stock_movements
├── id (PK)
├── product_id (FK)
├── movement_type (in/out/adjustment)
├── quantity
├── reference
├── notes
├── created_by (FK)
└── created_at

audit_logs
├── id (PK)
├── user_id (FK)
├── action (CREATE/UPDATE/DELETE)
├── entity_type
├── entity_id
├── changes (JSON)
├── ip_address
└── created_at
```

## Redis Cache Strategy

- **Product Details**: 5-minute TTL
- **Low Stock Alerts**: 5-minute TTL
- **Dashboard Stats**: 1-minute TTL
- **User Sessions**: 30-minute TTL

## Environment Variables

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379/0
SECRET_KEY=your-secret-key-from-vault
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
LOW_STOCK_THRESHOLD=10
DEBUG=false
```

## Next Steps (Phases 2-6)

### Phase 2: Containerize + Registry
- Multi-arch Docker builds (amd64 + arm64)
- Push to ghcr.io and Docker Hub
- Optimize image size

### Phase 3: Terraform Manual Deploy
- Create Terraform modules
- Deploy to Pi K8s cluster
- Set up PVC for PostgreSQL

### Phase 4: Vault Integration
- Store DB password in Vault
- Store JWT secret in Vault
- Use External Secrets Operator

### Phase 5: GitHub Actions CI/CD
- Build and push images
- Terraform plan on PR
- Terraform apply on merge

### Phase 6: ArgoCD GitOps
- Create Helm chart
- Set up ArgoCD application
- Auto-sync deployments

## Development

### Project Structure

```
app/
├── backend/
│   ├── main.py           # FastAPI app
│   ├── config.py         # Settings
│   ├── database.py       # DB connection
│   ├── models.py         # SQLAlchemy models
│   ├── schemas.py        # Pydantic schemas
│   ├── auth.py           # JWT authentication
│   ├── cache.py          # Redis cache service
│   ├── routes/
│   │   ├── auth.py       # Auth endpoints
│   │   ├── products.py   # Product CRUD
│   │   ├── categories.py # Category CRUD
│   │   ├── stock.py      # Stock movements
│   │   └── dashboard.py  # Dashboard stats
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/             # React app (Phase 1 continued)
└── docker-compose.yml
```

## License

MIT

## Author

Study Terraform Project - Enterprise Kubernetes Deployment
```
