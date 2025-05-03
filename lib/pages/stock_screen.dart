import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/recipe_card.dart';
import '../bottom_navigation.dart';
import '../pages/recipe_detail_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Rekomendasi Resep'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari resep...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                              : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        // This triggers rebuilding to show/hide clear button
                      });
                    },
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
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Rekomendasi'),
                      Tab(text: 'Favorit'),
                      Tab(text: 'Riwayat'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Recommended Tab
                        ListView(
                          padding: const EdgeInsets.only(top: 16),
                          children: [
                            _buildWideRecipeCard(
                              context,
                              title: 'Tumis Bayam Tomat',
                              ingredients: const ['Bayam', 'Tomat', 'Bawang'],
                              missingIngredients: const [],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Tumis bayam tomat adalah hidangan sehat yang mudah dibuat. Cocok untuk menu makan siang atau makan malam yang praktis dan bergizi.',
                            ),
                            const SizedBox(height: 16),
                            _buildWideRecipeCard(
                              context,
                              title: 'Telur Dadar Spesial',
                              ingredients: const ['Telur', 'Tomat'],
                              missingIngredients: const ['Daun Bawang'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Telur dadar dengan tambahan sayuran yang lezat. Cocok untuk sarapan atau menu makan praktis sehari-hari.',
                            ),
                            const SizedBox(height: 16),
                            _buildWideRecipeCard(
                              context,
                              title: 'Sandwich Telur',
                              ingredients: const ['Telur', 'Roti'],
                              missingIngredients: const ['Selada', 'Mayones'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Sandwich telur yang lezat dengan roti panggang, cocok untuk sarapan cepat atau bekal ke kantor dan sekolah.',
                            ),
                            const SizedBox(height: 16),
                            _buildWideRecipeCard(
                              context,
                              title: 'Sup Sayuran',
                              ingredients: const ['Wortel', 'Kentang'],
                              missingIngredients: const ['Brokoli', 'Kaldu'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Sup sayuran hangat yang menyehatkan, kaya akan vitamin dan nutrisi. Cocok disantap di musim hujan.',
                            ),
                          ],
                        ),
                        // Favorites Tab
                        ListView(
                          padding: const EdgeInsets.only(top: 16),
                          children: [
                            _buildWideRecipeCard(
                              context,
                              title: 'Nasi Goreng Spesial',
                              ingredients: const ['Telur', 'Wortel'],
                              missingIngredients: const ['Nasi', 'Kecap'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Nasi goreng spesial dengan bumbu rahasia yang lezat. Makanan favorit semua orang Indonesia.',
                            ),
                            const SizedBox(height: 16),
                            _buildWideRecipeCard(
                              context,
                              title: 'Smoothie Apel',
                              ingredients: const ['Apel', 'Susu UHT'],
                              missingIngredients: const ['Madu', 'Es Batu'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Minuman sehat dan menyegarkan dari apel segar. Cocok untuk menemani sarapan atau camilan sore hari.',
                            ),
                          ],
                        ),
                        // History Tab
                        ListView(
                          padding: const EdgeInsets.only(top: 16),
                          children: [
                            _buildWideRecipeCard(
                              context,
                              title: 'Telur Dadar Spesial',
                              ingredients: const ['Telur', 'Tomat'],
                              missingIngredients: const ['Daun Bawang'],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Telur dadar dengan tambahan sayuran yang lezat. Cocok untuk sarapan atau menu makan praktis sehari-hari.',
                            ),
                            const SizedBox(height: 16),
                            _buildWideRecipeCard(
                              context,
                              title: 'Tumis Bayam Tomat',
                              ingredients: const ['Bayam', 'Tomat', 'Bawang'],
                              missingIngredients: const [],
                              imageUrl: 'https://via.placeholder.com/300x200',
                              description:
                                  'Tumis bayam tomat adalah hidangan sehat yang mudah dibuat. Cocok untuk menu makan siang atau makan malam yang praktis dan bergizi.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating action button for adding new recipes
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        onPressed: () {
          // Show add recipe dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tambah resep baru')));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWideRecipeCard(
    BuildContext context, {
    required String title,
    required List<String> ingredients,
    required List<String> missingIngredients,
    required String imageUrl,
    required String description,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to recipe detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RecipeDetailScreen(
                    title: title,
                    ingredients: ingredients,
                    missingIngredients: missingIngredients,
                    imageUrl: imageUrl,
                    cookingSteps: [
                      {
                        'instruction':
                            'Siapkan semua bahan yang dibutuhkan dan cuci bersih.',
                        'imageUrl':
                            'https://images.unsplash.com/photo-1526470498-9ae73c665de8?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                      },
                      {
                        'instruction':
                            'Potong semua bahan sesuai kebutuhan resep.',
                        'imageUrl':
                            'https://images.unsplash.com/photo-1516986000070-2734a6a9f6ee?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                      },
                      {
                        'instruction': 'Masak dengan api sedang hingga matang.',
                        'imageUrl':
                            'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                      },
                    ],
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak dapat memuat gambar',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () {},
                      iconSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Available ingredients
                  if (ingredients.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bahan yang tersedia:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              ingredients
                                  .map(
                                    (ingredient) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFD1FAE5),
                                        ),
                                      ),
                                      child: Text(
                                        ingredient,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Missing ingredients
                  if (missingIngredients.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bahan yang kurang:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              missingIngredients
                                  .map(
                                    (ingredient) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        ingredient,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Beli Bahan'),
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.restaurant),
                          label: const Text('Lihat Resep'),
                          onPressed: () {
                            // Navigate to recipe detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RecipeDetailScreen(
                                      title: title,
                                      ingredients: ingredients,
                                      missingIngredients: missingIngredients,
                                      imageUrl: imageUrl,
                                      cookingSteps: [
                                        {
                                          'instruction':
                                              'Siapkan semua bahan yang dibutuhkan dan cuci bersih.',
                                          'imageUrl':
                                              'https://images.unsplash.com/photo-1526470498-9ae73c665de8?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                                        },
                                        {
                                          'instruction':
                                              'Potong semua bahan sesuai kebutuhan resep.',
                                          'imageUrl':
                                              'https://images.unsplash.com/photo-1516986000070-2734a6a9f6ee?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                                        },
                                        {
                                          'instruction':
                                              'Masak dengan api sedang hingga matang.',
                                          'imageUrl':
                                              'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                                        },
                                      ],
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
