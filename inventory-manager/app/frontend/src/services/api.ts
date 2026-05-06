import axios from 'axios';
import type {
  User,
  LoginResponse,
  LoginFormData,
  Category,
  Product,
  ProductFormData,
  StockMovement,
  StockMovementFormData,
  DashboardStats,
  LowStockItem,
} from '../types';

// Base configuration
// Use relative URL to go through Nginx proxy
const API_BASE_URL = '';  // Empty string means same origin
const API_VERSION = '/api/v1';

const api = axios.create({
  baseURL: `${API_BASE_URL}${API_VERSION}`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Authentication
export const authService = {
  async login(credentials: LoginFormData): Promise<LoginResponse> {
    const formData = new URLSearchParams();
    formData.append('username', credentials.username);
    formData.append('password', credentials.password);
    
    const { data } = await api.post<LoginResponse>('/auth/login', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
    return data;
  },

  async getCurrentUser(): Promise<User> {
    const { data } = await api.get<User>('/auth/me');
    return data;
  },

  logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  },
};

// Categories
export const categoryService = {
  async getAll(): Promise<Category[]> {
    const { data } = await api.get<Category[]>('/categories/');
    return data;
  },

  async getById(id: number): Promise<Category> {
    const { data } = await api.get<Category>(`/categories/${id}`);
    return data;
  },

  async create(category: Omit<Category, 'id' | 'created_at' | 'updated_at'>): Promise<Category> {
    const { data } = await api.post<Category>('/categories/', category);
    return data;
  },

  async update(id: number, category: Partial<Category>): Promise<Category> {
    const { data } = await api.put<Category>(`/categories/${id}`, category);
    return data;
  },

  async delete(id: number): Promise<void> {
    await api.delete(`/categories/${id}`);
  },
};

// Products
export const productService = {
  async getAll(): Promise<Product[]> {
    const { data } = await api.get<Product[]>('/products/');
    return data;
  },

  async getById(id: number): Promise<Product> {
    const { data } = await api.get<Product>(`/products/${id}`);
    return data;
  },

  async create(product: ProductFormData): Promise<Product> {
    const { data } = await api.post<Product>('/products/', product);
    return data;
  },

  async update(id: number, product: Partial<ProductFormData>): Promise<Product> {
    const { data } = await api.put<Product>(`/products/${id}`, product);
    return data;
  },

  async delete(id: number): Promise<void> {
    await api.delete(`/products/${id}`);
  },
};

// Stock Movements
export const stockService = {
  async getAll(): Promise<StockMovement[]> {
    const { data } = await api.get<StockMovement[]>('/stock/');
    return data;
  },

  async getByProduct(productId: number): Promise<StockMovement[]> {
    const { data } = await api.get<StockMovement[]>(`/stock/product/${productId}`);
    return data;
  },

  async create(movement: StockMovementFormData): Promise<StockMovement> {
    const { data } = await api.post<StockMovement>('/stock/', movement);
    return data;
  },
};

// Dashboard
export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const { data } = await api.get<DashboardStats>('/dashboard/stats');
    return data;
  },

  async getLowStockItems(): Promise<LowStockItem[]> {
    const { data } = await api.get<LowStockItem[]>('/dashboard/low-stock');
    return data;
  },
};

export default api;
