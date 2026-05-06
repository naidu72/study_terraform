import React from 'react';
import {
  Container,
  Paper,
  Typography,
  Box,
  Card,
  CardContent,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  Inventory as InventoryIcon,
  Category as CategoryIcon,
  Warning as WarningIcon,
  AttachMoney as MoneyIcon,
  TrendingUp as TrendingIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { dashboardService } from '../services/api';
import { formatCurrency, formatNumber } from '../utils/helpers';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';

const Dashboard: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = React.useState(false);

  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardService.getStats(),
  });

  const { data: lowStockItems } = useQuery({
    queryKey: ['low-stock'],
    queryFn: () => dashboardService.getLowStockItems(),
  });

  const statCards = [
    {
      title: 'Total Products',
      value: stats?.total_products || 0,
      icon: <InventoryIcon sx={{ fontSize: 40 }} />,
      color: '#1976d2',
    },
    {
      title: 'Categories',
      value: stats?.total_categories || 0,
      icon: <CategoryIcon sx={{ fontSize: 40 }} />,
      color: '#9c27b0',
    },
    {
      title: 'Low Stock Items',
      value: stats?.low_stock_items || 0,
      icon: <WarningIcon sx={{ fontSize: 40 }} />,
      color: '#ed6c02',
    },
    {
      title: 'Total Stock Value',
      value: stats ? formatCurrency(stats.total_stock_value) : '$0',
      icon: <MoneyIcon sx={{ fontSize: 40 }} />,
      color: '#2e7d32',
    },
    {
      title: 'Recent Movements',
      value: stats?.recent_movements || 0,
      icon: <TrendingIcon sx={{ fontSize: 40 }} />,
      color: '#0288d1',
    },
  ];

  if (error) {
    return (
      <Box>
        <Header onMenuClick={() => setSidebarOpen(true)} />
        <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
          <Alert severity="error">Failed to load dashboard data</Alert>
        </Container>
      </Box>
    );
  }

  return (
    <Box>
      <Header onMenuClick={() => setSidebarOpen(true)} />
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Dashboard
        </Typography>

          {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            {/* Stats Cards */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mb: 4 }}>
              {statCards.map((card, index) => (
                <Box key={index} sx={{ flex: '1 1 calc(20% - 16px)', minWidth: '200px' }}>
                  <Card elevation={2}>
                    <CardContent>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Box>
                          <Typography color="text.secondary" variant="body2" gutterBottom>
                            {card.title}
                          </Typography>
                          <Typography variant="h5" component="div">
                            {typeof card.value === 'number' ? formatNumber(card.value) : card.value}
                          </Typography>
                        </Box>
                        <Box sx={{ color: card.color }}>{card.icon}</Box>
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
              ))}
            </Box>

            {/* Low Stock Alerts */}
            {lowStockItems && lowStockItems.length > 0 && (
              <Paper elevation={2} sx={{ p: 3 }}>
                <Typography variant="h6" gutterBottom color="warning.main">
                  <WarningIcon sx={{ verticalAlign: 'middle', mr: 1 }} />
                  Low Stock Alerts
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mt: 2 }}>
                  {lowStockItems.map((item) => (
                    <Box key={item.product.id} sx={{ flex: '1 1 calc(33.333% - 16px)', minWidth: '250px' }}>
                      <Card variant="outlined" sx={{ borderColor: 'warning.main' }}>
                        <CardContent>
                          <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>
                            {item.product.name}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            SKU: {item.product.sku}
                          </Typography>
                          <Box sx={{ mt: 1 }}>
                            <Typography variant="body2">
                              Current: <strong>{item.current_quantity}</strong>
                            </Typography>
                            <Typography variant="body2">
                              Reorder Level: <strong>{item.reorder_level}</strong>
                            </Typography>
                            <Typography variant="body2" color="error.main">
                              Shortage: <strong>{item.shortage}</strong>
                            </Typography>
                          </Box>
                        </CardContent>
                      </Card>
                    </Box>
                  ))}
                </Box>
              </Paper>
            )}
          </>
        )}
      </Container>
    </Box>
  );
};

export default Dashboard;
