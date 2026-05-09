import React, { useState } from 'react';
import {
  Container,
  Box,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Chip,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { stockService, productService } from '../services/api';
import { formatDate, getMovementTypeColor } from '../utils/helpers';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import type { StockMovementFormData } from '../types';

const StockMovements: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<StockMovementFormData>({
    product_id: 0,
    movement_type: 'IN',
    quantity: 0,
    reference_number: '',
    notes: '',
  });
  const queryClient = useQueryClient();

  const { data: movements, isLoading, error } = useQuery({
    queryKey: ['stock-movements'],
    queryFn: () => stockService.getAll(),
  });

  const { data: products } = useQuery({
    queryKey: ['products'],
    queryFn: () => productService.getAll(),
  });

  const createMutation = useMutation({
    mutationFn: (data: StockMovementFormData) => stockService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stock-movements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      handleCloseDialog();
    },
  });

  const handleOpenDialog = () => {
    setFormData({
      product_id: products?.[0]?.id || 0,
      movement_type: 'IN',
      quantity: 0,
      reference_number: '',
      notes: '',
    });
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate(formData);
  };

  if (error) {
    return (
      <Box>
        <Header onMenuClick={() => setSidebarOpen(true)} />
        <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
          <Alert severity="error">Failed to load stock movements</Alert>
        </Container>
      </Box>
    );
  }

  return (
    <Box>
      <Header onMenuClick={() => setSidebarOpen(true)} />
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Typography variant="h4">Stock Movements</Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleOpenDialog}
          >
            Record Movement
          </Button>
        </Box>

        {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
            <CircularProgress />
          </Box>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Date</TableCell>
                  <TableCell>Product</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell align="right">Quantity</TableCell>
                  <TableCell>Reference</TableCell>
                  <TableCell>Notes</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {movements?.map((movement) => (
                  <TableRow key={movement.id}>
                    <TableCell>{formatDate(movement.created_at)}</TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                        {movement.product?.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        SKU: {movement.product?.sku}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={movement.movement_type}
                        color={getMovementTypeColor(movement.movement_type) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography
                        variant="body2"
                        color={
                          movement.movement_type === 'IN'
                            ? 'success.main'
                            : movement.movement_type === 'OUT'
                            ? 'error.main'
                            : 'warning.main'
                        }
                      >
                        {movement.movement_type === 'OUT' ? '-' : '+'}
                        {movement.quantity}
                      </Typography>
                    </TableCell>
                    <TableCell>{movement.reference_number || '-'}</TableCell>
                    <TableCell>{movement.notes || '-'}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}

        {/* Movement Dialog */}
        <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
          <form onSubmit={handleSubmit}>
            <DialogTitle>Record Stock Movement</DialogTitle>
            <DialogContent>
              <TextField
                fullWidth
                select
                label="Product"
                name="product_id"
                value={formData.product_id}
                onChange={(e) =>
                  setFormData({ ...formData, product_id: Number(e.target.value) })
                }
                margin="normal"
                required
              >
                {products?.map((product) => (
                  <MenuItem key={product.id} value={product.id}>
                    {product.name} (SKU: {product.sku})
                  </MenuItem>
                ))}
              </TextField>
              <TextField
                fullWidth
                select
                label="Movement Type"
                name="movement_type"
                value={formData.movement_type}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    movement_type: e.target.value as 'IN' | 'OUT' | 'ADJUSTMENT',
                  })
                }
                margin="normal"
                required
              >
                <MenuItem value="IN">Stock In (Receive)</MenuItem>
                <MenuItem value="OUT">Stock Out (Issue)</MenuItem>
                <MenuItem value="ADJUSTMENT">Adjustment</MenuItem>
              </TextField>
              <TextField
                fullWidth
                label="Quantity"
                name="quantity"
                type="number"
                value={formData.quantity}
                onChange={(e) =>
                  setFormData({ ...formData, quantity: Number(e.target.value) })
                }
                margin="normal"
                required
              />
              <TextField
                fullWidth
                label="Reference Number"
                name="reference_number"
                value={formData.reference_number}
                onChange={(e) =>
                  setFormData({ ...formData, reference_number: e.target.value })
                }
                margin="normal"
                placeholder="PO#, Invoice#, etc."
              />
              <TextField
                fullWidth
                label="Notes"
                name="notes"
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                margin="normal"
                multiline
                rows={2}
              />
            </DialogContent>
            <DialogActions>
              <Button onClick={handleCloseDialog}>Cancel</Button>
              <Button type="submit" variant="contained">
                Record Movement
              </Button>
            </DialogActions>
          </form>
        </Dialog>
      </Container>
    </Box>
  );
};

export default StockMovements;
