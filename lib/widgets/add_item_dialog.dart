import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_item_model.dart';

class AddItemDialog extends ConsumerStatefulWidget {
  const AddItemDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'gram';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _isPackaged = false;

  final List<String> _units = ['gram', 'kg', 'pcs', 'liter', 'ml', 'pack'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      debugPrint('🔄 Submitting new food item:');
      debugPrint('📝 Name: ${_nameController.text}');
      debugPrint('📝 Quantity: ${_quantityController.text} $_selectedUnit');
      debugPrint('📝 Expiry Date: ${_expiryDate.toIso8601String()}');
      debugPrint('📝 Is Packaged: $_isPackaged');

      try {
        // Create food item
        final item = FoodItem(
          id: '', // Will be assigned by the server
          name: _nameController.text,
          quantity: int.parse(_quantityController.text),
          unit: _selectedUnit,
          expiryDate: _expiryDate,
          category: 'lainnya', // Default category
          status: 'active', // Default status
          isPackaged: _isPackaged,
          userId: '', // Will be assigned by the server
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Debug API payload
        final payload = item.toJson();
        debugPrint('📤 API Request Payload: ${payload.toString()}');

        // Add item using the food provider
        final result = await ref
            .read(foodItemsProvider.notifier)
            .addFoodItem(item);

        if (mounted) {
          if (result['success']) {
            debugPrint('✅ Food item added successfully');
            // Show detailed response data
            if (result.containsKey('data')) {
              debugPrint('📥 API Response Data: ${result['data'].toString()}');
            }

            // Close dialog on success
            Navigator.of(context).pop();
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            debugPrint('❌ Failed to add food item: ${result['message']}');
            // Log detailed error information
            if (result.containsKey('error')) {
              debugPrint('⚠️ Error details: ${result['error']}');
            }
            if (result.containsKey('error_code')) {
              debugPrint('⚠️ Error code: ${result['error_code']}');
            }

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal menambahkan item'),
                backgroundColor: Colors.red,
              ),
            );

            // If unauthorized, close dialog
            if (result.containsKey('unauthorized') &&
                result['unauthorized'] == true) {
              Navigator.of(context).pop();
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Exception in _submitForm: $e');
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Item Makanan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Makanan',
                  hintText: 'Masukkan nama makanan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and unit fields
              Row(
                children: [
                  // Quantity field
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        hintText: 'Jumlah',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Unit dropdown
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                      items:
                          _units
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Expiry date field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Kadaluarsa',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id').format(_expiryDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Is Packaged switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Makanan Kemasan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _isPackaged,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _isPackaged = value;
                            });
                            debugPrint('🔄 isPackaged changed to: $value');
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Aktifkan jika makanan ini merupakan produk kemasan dengan label kadaluarsa dari pabrik.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Simpan'),
        ),
      ],
    );
  }
}
