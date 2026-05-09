import React from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Divider,
  Box,
  Typography,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Inventory as InventoryIcon,
  Category as CategoryIcon,
  TrendingUp as TrendingUpIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

const menuItems = [
  { path: '/dashboard', label: 'Dashboard', icon: <DashboardIcon /> },
  { path: '/products', label: 'Products', icon: <InventoryIcon /> },
  { path: '/categories', label: 'Categories', icon: <CategoryIcon /> },
  { path: '/stock-movements', label: 'Stock Movements', icon: <TrendingUpIcon /> },
  { path: '/low-stock', label: 'Low Stock Alerts', icon: <WarningIcon /> },
];

const Sidebar: React.FC<SidebarProps> = ({ open, onClose }) => {
  const navigate = useNavigate();
  const location = useLocation();

  const handleNavigate = (path: string) => {
    navigate(path);
    onClose();
  };

  return (
    <Drawer anchor="left" open={open} onClose={onClose}>
      <Box sx={{ width: 250 }} role="presentation">
        <Box sx={{ p: 2 }}>
          <Typography variant="h6" color="primary">
            Inventory Manager
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Management System
          </Typography>
        </Box>
        <Divider />
        <List>
          {menuItems.map((item) => (
            <ListItem key={item.path} disablePadding>
              <ListItemButton
                selected={location.pathname === item.path}
                onClick={() => handleNavigate(item.path)}
              >
                <ListItemIcon>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </Box>
    </Drawer>
  );
};

export default Sidebar;
