import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/barter_card.dart';

class BarterScreen extends StatelessWidget {
  const BarterScreen({Key? key}) : super(key: key);

  // Method untuk membuka maps (simulasi)
  void _openMapsSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari produk barter...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey[200], // Placeholder untuk maps
                        child: const Center(
                          child: Text('Peta akan ditampilkan di sini'),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF22C55E),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Pilih Lokasi Ini'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Barter Makanan'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area pencarian lokasi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: InkWell(
                onTap: () => _openMapsSearch(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cari produk barter di sekitar Anda...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '5 km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Biaya barter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '5 Koin per transaksi barter',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Tabs section - Menggunakan Expanded untuk mencegah overflow
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Tersedia'),
                        Tab(text: 'Produk Saya'),
                        Tab(text: 'Riwayat'),
                      ],
                      labelColor: Color(0xFF22C55E),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 4),
                    // Menggunakan Expanded untuk TabBarView agar bisa mengambil sisa ruang yang tersedia
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Available Tab
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            padding: const EdgeInsets.all(12),
                            itemCount: 6,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final items = [
                                {
                                  'title': 'Mie Instan (5 pcs)',
                                  'owner': 'Ahmad',
                                  'distance': '0.8 km',
                                  'expiryDate': DateTime(2025, 6, 10),
                                },
                                {
                                  'title': 'Beras 2kg',
                                  'owner': 'Siti',
                                  'distance': '1.5 km',
                                  'expiryDate': DateTime(2025, 8, 15),
                                },
                                {
                                  'title': 'Minyak Goreng 1L',
                                  'owner': 'Budi',
                                  'distance': '2.1 km',
                                  'expiryDate': DateTime(2025, 7, 20),
                                },
                                {
                                  'title': 'Gula Pasir 1kg',
                                  'owner': 'Dewi',
                                  'distance': '3.2 km',
                                  'expiryDate': DateTime(2025, 6, 25),
                                },
                                {
                                  'title': 'Tepung Terigu 500g',
                                  'owner': 'Rina',
                                  'distance': '1.8 km',
                                  'expiryDate': DateTime(2025, 7, 15),
                                },
                                {
                                  'title': 'Telur Ayam 1 kg',
                                  'owner': 'Joko',
                                  'distance': '2.7 km',
                                  'expiryDate': DateTime(2025, 6, 5),
                                },
                              ];

                              final item = items[index];
                              return BarterCard(
                                title: item['title'] as String,
                                owner: item['owner'] as String,
                                distance: item['distance'] as String,
                                expiryDate: item['expiryDate'] as DateTime,
                                imageUrl: 'https://via.placeholder.com/200x150',
                              );
                            },
                          ),

                          // My Products Tab
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            padding: const EdgeInsets.all(12),
                            itemCount: 2,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final items = [
                                {
                                  'title': 'Susu UHT 1L',
                                  'owner': 'Anda',
                                  'distance': '0 km',
                                  'expiryDate': DateTime(2025, 5, 20),
                                },
                                {
                                  'title': 'Telur Ayam 1kg',
                                  'owner': 'Anda',
                                  'distance': '0 km',
                                  'expiryDate': DateTime(2025, 4, 25),
                                },
                              ];

                              final item = items[index];
                              return BarterCard(
                                title: item['title'] as String,
                                owner: item['owner'] as String,
                                distance: item['distance'] as String,
                                expiryDate: item['expiryDate'] as DateTime,
                                imageUrl: 'https://via.placeholder.com/200x150',
                              );
                            },
                          ),

                          // History Tab
                          ListView(
                            padding: const EdgeInsets.all(12),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Barter dengan Ahmad',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '20 Maret 2025',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Text(
                                              'Selesai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Anda memberikan',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Roti Gandum (1 bungkus)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Icon(
                                              Icons.swap_horiz,
                                              color: Colors.grey[400],
                                              size: 24,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Anda menerima',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Mie Instan (3 pcs)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '-5 Koin digunakan',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Barter dengan Siti',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '15 Maret 2025',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Text(
                                              'Selesai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Anda memberikan',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Susu UHT (1 liter)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Icon(
                                              Icons.swap_horiz,
                                              color: Colors.grey[400],
                                              size: 24,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Anda menerima',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Beras (1 kg)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '-5 Koin digunakan',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        backgroundColor: const Color(0xFF22C55E),
        onPressed: () {
          // Show add product dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tambah produk barter baru')),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
