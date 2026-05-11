# Inventory Manager - React Frontend

A modern, responsive web application for inventory management built with React, TypeScript, and Material-UI.

## Features

- 🔐 **Authentication** - JWT-based login with role-based access control
- 📊 **Dashboard** - Real-time statistics and low stock alerts
- 📦 **Product Management** - Complete CRUD operations for products
- 📂 **Category Management** - Organize products by categories
- 📈 **Stock Movements** - Track inventory in/out/adjustments
- ⚠️ **Low Stock Alerts** - Visual warnings for items below reorder level
- 🎨 **Modern UI** - Material-UI components with responsive design
- 🚀 **Fast** - Optimized React Query for data fetching

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Material-UI (MUI)** - Component library
- **React Router** - Client-side routing
- **React Query** - Data fetching and caching
- **Axios** - HTTP client
- **Recharts** - Charts and visualizations

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Backend API running (see `../backend/README.md`)

### Installation

```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env to point to your backend API
# REACT_APP_API_URL=http://localhost:8000
```

### Development

```bash
# Start development server
npm start

# Open http://localhost:3000 in your browser
```

### Build for Production

```bash
# Create optimized production build
npm run build

# The build folder contains the compiled application
```

### Docker Build

```bash
# Build multi-arch image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  --push .
```

## Default Credentials

- **Username:** admin
- **Password:** admin123

## Project Structure

```
src/
├── components/         # Reusable UI components
│   ├── Header.tsx     # App header with user menu
│   ├── Sidebar.tsx    # Navigation sidebar
│   └── PrivateRoute.tsx # Protected route wrapper
├── pages/             # Main application pages
│   ├── Login.tsx      # Login page
│   ├── Dashboard.tsx  # Dashboard with stats
│   ├── Products.tsx   # Product management
│   ├── Categories.tsx # Category management
│   └── StockMovements.tsx # Stock tracking
├── services/          # API services
│   └── api.ts        # Axios instance and API calls
├── types/            # TypeScript type definitions
│   └── index.ts      # All type interfaces
├── utils/            # Utility functions
│   └── helpers.ts    # Helper functions
└── App.tsx           # Main app component with routing
```

## API Configuration

The frontend communicates with the backend API via the `REACT_APP_API_URL` environment variable.

**Development:**
```env
REACT_APP_API_URL=http://localhost:8000
```

**Production (Kubernetes):**
```env
REACT_APP_API_URL=https://inventory-api.naidu72.info
```

## Features Detail

### Dashboard
- Total products count
- Category count
- Low stock items count
- Total stock value
- Recent movements count
- Visual alerts for low stock items

### Product Management
- Create, read, update, delete products
- SKU management
- Category assignment
- Quantity tracking
- Unit price management
- Reorder level configuration
- Location tracking
- Low stock status indicators

### Stock Movements
- Record stock IN (receiving)
- Record stock OUT (issuing)
- Stock adjustments
- Reference number tracking
- Movement notes
- Real-time quantity updates

### Categories
- Organize products by category
- Create and manage categories
- Category descriptions

## Deployment

The frontend is deployed as a static site served by Nginx.

**Kubernetes Deployment:**
- Built with multi-stage Dockerfile
- Served by Nginx alpine
- Deployed via Terraform
- Configured with environment-specific API URLs

## License

MIT
