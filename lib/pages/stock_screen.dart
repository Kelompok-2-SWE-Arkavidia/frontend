import 'package:flutter/material.dart';
import '../widgets/stock_item.dart';
import '../widgets/add_item_dialog.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({Key? key}) : super(key: key);

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddItemDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Makanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari item...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Semua'),
                        Tab(
                          child: Text(
                            'Aman',
                            style: TextStyle(color: Color(0xFF22C55E)),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Segera',
                            style: TextStyle(color: Color(0xFFF59E0B)),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Kadaluarsa',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // All Tab
                          ListView(
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              StockItem(
                                name: 'Bayam',
                                quantity: '1 ikat',
                                expiryDate: DateTime(2025, 4, 15),
                                status: 'warning',
                              ),
                              StockItem(
                                name: 'Susu UHT',
                                quantity: '1 liter',
                                expiryDate: DateTime(2025, 5, 20),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Roti Gandum',
                                quantity: '1 bungkus',
                                expiryDate: DateTime(2025, 4, 10),
                                status: 'expired',
                              ),
                              StockItem(
                                name: 'Telur Ayam',
                                quantity: '1 kg',
                                expiryDate: DateTime(2025, 4, 25),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Tomat',
                                quantity: '500 gr',
                                expiryDate: DateTime(2025, 4, 14),
                                status: 'warning',
                              ),
                              StockItem(
                                name: 'Wortel',
                                quantity: '250 gr',
                                expiryDate: DateTime(2025, 4, 20),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Kentang',
                                quantity: '1 kg',
                                expiryDate: DateTime(2025, 5, 10),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Apel',
                                quantity: '500 gr',
                                expiryDate: DateTime(2025, 4, 18),
                                status: 'safe',
                              ),
                            ],
                          ),
                          // Safe Tab
                          ListView(
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              StockItem(
                                name: 'Susu UHT',
                                quantity: '1 liter',
                                expiryDate: DateTime(2025, 5, 20),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Telur Ayam',
                                quantity: '1 kg',
                                expiryDate: DateTime(2025, 4, 25),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Wortel',
                                quantity: '250 gr',
                                expiryDate: DateTime(2025, 4, 20),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Kentang',
                                quantity: '1 kg',
                                expiryDate: DateTime(2025, 5, 10),
                                status: 'safe',
                              ),
                              StockItem(
                                name: 'Apel',
                                quantity: '500 gr',
                                expiryDate: DateTime(2025, 4, 18),
                                status: 'safe',
                              ),
                            ],
                          ),
                          // Warning Tab
                          ListView(
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              StockItem(
                                name: 'Bayam',
                                quantity: '1 ikat',
                                expiryDate: DateTime(2025, 4, 15),
                                status: 'warning',
                              ),
                              StockItem(
                                name: 'Tomat',
                                quantity: '500 gr',
                                expiryDate: DateTime(2025, 4, 14),
                                status: 'warning',
                              ),
                            ],
                          ),
                          // Expired Tab
                          ListView(
                            padding: const EdgeInsets.only(top: 16),
                            children: [
                              StockItem(
                                name: 'Roti Gandum',
                                quantity: '1 bungkus',
                                expiryDate: DateTime(2025, 4, 10),
                                status: 'expired',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Resep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Donasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Barter',
          ),
        ],
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}
