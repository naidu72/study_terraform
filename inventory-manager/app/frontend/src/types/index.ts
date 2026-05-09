// API Response Types
export interface User {
  id: number;
  username: string;
  email: string;
  full_name: string;
  role: 'admin' | 'manager' | 'viewer';
  is_active: boolean;
  created_at: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
}

export interface Category {
  id: number;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: number;
  sku: string;
  name: string;
  description?: string;
  category_id: number;
  category?: Category;
  quantity: number;
  unit_price: number;
  reorder_level: number;
  location?: string;
  created_at: string;
  updated_at: string;
}

export interface StockMovement {
  id: number;
  product_id: number;
  product?: Product;
  movement_type: 'IN' | 'OUT' | 'ADJUSTMENT';
  quantity: number;
  reference_number?: string;
  notes?: string;
  created_by?: number;
  created_at: string;
}

export interface DashboardStats {
  total_products: number;
  total_categories: number;
  low_stock_items: number;
  total_stock_value: number;
  recent_movements: number;
}

export interface LowStockItem {
  product: Product;
  current_quantity: number;
  reorder_level: number;
  shortage: number;
}

// Form Types
export interface LoginFormData {
  username: string;
  password: string;
}

export interface ProductFormData {
  sku: string;
  name: string;
  description?: string;
  category_id: number;
  quantity: number;
  unit_price: number;
  reorder_level: number;
  location?: string;
}

export interface StockMovementFormData {
  product_id: number;
  movement_type: 'IN' | 'OUT' | 'ADJUSTMENT';
  quantity: number;
  reference_number?: string;
  notes?: string;
}

// API Error Response
export interface ApiError {
  detail: string;
}
