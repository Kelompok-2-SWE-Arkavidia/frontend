import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_item.dart';
import '../models/food_item_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReceiptConfirmationScreen extends StatefulWidget {
  final List<ReceiptItem> items;
  final String scanId;

  const ReceiptConfirmationScreen({
    Key? key,
    required this.items,
    required this.scanId,
  }) : super(key: key);

  @override
  State<ReceiptConfirmationScreen> createState() =>
      _ReceiptConfirmationScreenState();
}

class _ReceiptConfirmationScreenState extends State<ReceiptConfirmationScreen> {
  late List<ReceiptItem> _items;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ApiService apiService = ApiService();

      // Save all items to the server using the food-items endpoint
      for (final item in _items) {
        // Convert receipt item to food item
        final foodItem = FoodItem(
          id: '', // New item, empty ID
          name: item.name,
          expiryDate: DateTime.parse(item.expiryDate),
          quantity: item.quantity,
          unit: item.unitMeasure,
          status: 'active', // Default status
          isPackaged: item.isPackaged,
          createdAt: DateTime.now(),
        );

        await apiService.addFoodItem(foodItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan')));
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAllItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ApiService apiService = ApiService();

      // Convert items to the format expected by the API
      for (final item in _items) {
        // Convert receipt item to food item
        final foodItem = FoodItem(
          id: '', // New item, empty ID
          name: item.name,
          expiryDate: DateTime.parse(item.expiryDate),
          quantity: item.quantity,
          unit: item.unitMeasure,
          status: 'active', // Default status
          isPackaged: item.isPackaged,
          createdAt: DateTime.now(),
        );

        await apiService.addFoodItem(foodItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua item berhasil disimpan')),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editItem(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildEditSheet(index),
    );
  }

  // Format harga dalam Rupiah dengan penanganan nilai yang tidak sesuai
  String formatRupiah(double price) {
    // Validasi nilai harga (backend issue fallback)
    double validatedPrice = price;
    
    // Jika harga terlalu kecil (kemungkinan backend issue), kalikan dengan 1000
    if (validatedPrice > 0 && validatedPrice < 1000) {
      validatedPrice = validatedPrice * 1000;
    }
    
    // Format harga sesuai standar Rupiah
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(validatedPrice);
  }

  // Menghitung total harga semua item
  double getTotalPrice() {
    double total = 0;
    for (var item in _items) {
      total += item.price;
    }
    return total;
  }

  Widget _buildEditSheet(int index) {
    final item = _items[index];
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final priceController = TextEditingController(text: item.price.toString());
    final expDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.parse(item.expiryDate)),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expDateController,
              decoration: const InputDecoration(
                labelText: 'Expiry Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(item.expiryDate),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(
                    const Duration(days: 1825),
                  ), // 5 years
                );

                if (date != null) {
                  expDateController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(date);
                }
              },
              readOnly: true,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final updatedItem = ReceiptItem(
                      name: nameController.text,
                      category: item.category,
                      price:
                          double.tryParse(priceController.text) ?? item.price,
                      quantity:
                          int.tryParse(quantityController.text) ??
                          item.quantity,
                      unitMeasure: item.unitMeasure,
                      expiryDate: expDateController.text,
                      isPackaged: item.isPackaged,
                      estimatedAge: item.estimatedAge,
                      confidence: item.confidence,
                    );

                    setState(() {
                      _items[index] = updatedItem;
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Struk Belanja'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveAllItems,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save_alt),
            label: const Text('Simpan Semua'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card with item count and save all button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ringkasan Struk Belanja',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total item: ${_items.length}'),
                        Text(
                          'Total: ${formatRupiah(getTotalPrice())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveAllItems,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Tambahkan Semua ke Inventori'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // List of items
          Expanded(
            child:
                _items.isEmpty
                    ? const Center(child: Text('Tidak ada data item'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final expiryDate = DateTime.parse(item.expiryDate);
                        final now = DateTime.now();
                        final daysUntilExpiry =
                            expiryDate.difference(now).inDays;

                        Color statusColor = Colors.green;
                        if (daysUntilExpiry < 0) {
                          statusColor = Colors.red;
                        } else if (daysUntilExpiry < 3) {
                          statusColor = Colors.orange;
                        } else if (daysUntilExpiry < 7) {
                          statusColor = Colors.yellow;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _editItem(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.category,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                formatRupiah(item.price),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                '${item.quantity} ${item.unitMeasure}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: Colors.grey[200],
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(
                                                'Exp: ${DateFormat('dd MMM yyyy').format(expiryDate)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: statusColor
                                                  .withOpacity(0.2),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => _editItem(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
