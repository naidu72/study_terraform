import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  IconButton,
  Box,
  Avatar,
  Menu,
  MenuItem,
  Chip,
} from '@mui/material';
import {
  Menu as MenuIcon,
  AccountCircle,
  Logout,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/api';
import { getUser, removeToken, removeUser, getRoleColor } from '../utils/helpers';

interface HeaderProps {
  onMenuClick?: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const navigate = useNavigate();
  const user = getUser();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    authService.logout();
    removeToken();
    removeUser();
    navigate('/login');
  };

  return (
    <AppBar position="static">
      <Toolbar>
        {onMenuClick && (
          <IconButton
            size="large"
            edge="start"
            color="inherit"
            aria-label="menu"
            sx={{ mr: 2 }}
            onClick={onMenuClick}
          >
            <MenuIcon />
          </IconButton>
        )}
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Inventory Manager
        </Typography>

        {user && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Chip
              label={user.role.toUpperCase()}
              color={getRoleColor(user.role) as any}
              size="small"
            />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Avatar sx={{ width: 32, height: 32 }}>
                {user.username[0].toUpperCase()}
              </Avatar>
              <IconButton
                size="large"
                aria-label="account of current user"
                aria-controls="menu-appbar"
                aria-haspopup="true"
                onClick={handleMenu}
                color="inherit"
              >
                <AccountCircle />
              </IconButton>
            </Box>
            <Menu
              id="menu-appbar"
              anchorEl={anchorEl}
              anchorOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              open={Boolean(anchorEl)}
              onClose={handleClose}
            >
              <MenuItem disabled>
                <Typography variant="body2">
                  {user.full_name || user.username}
                </Typography>
              </MenuItem>
              <MenuItem disabled>
                <Typography variant="caption" color="text.secondary">
                  {user.email}
                </Typography>
              </MenuItem>
              <MenuItem onClick={handleLogout}>
                <Logout fontSize="small" sx={{ mr: 1 }} />
                Logout
              </MenuItem>
            </Menu>
          </Box>
        )}
      </Toolbar>
    </AppBar>
  );
};

export default Header;
