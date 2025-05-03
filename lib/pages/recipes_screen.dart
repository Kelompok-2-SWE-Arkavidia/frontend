import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../bottom_navigation.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Rekomendasi Resep',
        actions: [
          Row(
            children: [
              Text(
                '15 Koin',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu, size: 16),
                label: const Text('Dapatkan Resep'),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
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
                      hintText: 'Cari resep...',
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
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Rekomendasi'),
                        Tab(text: 'Favorit'),
                        Tab(text: 'Riwayat'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Recommended Tab
                          GridView.count(
                            padding: const EdgeInsets.only(top: 16),
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              RecipeCard(
                                title: 'Tumis Bayam Tomat',
                                ingredients: const ['Bayam', 'Tomat', 'Bawang'],
                                missingIngredients: const [],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1576866209830-589e1bfbaa4d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                              RecipeCard(
                                title: 'Telur Dadar Spesial',
                                ingredients: const ['Telur', 'Tomat'],
                                missingIngredients: const ['Daun Bawang'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1606851094291-6efae152bb87?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                              RecipeCard(
                                title: 'Sandwich Telur',
                                ingredients: const ['Telur', 'Roti'],
                                missingIngredients: const ['Selada', 'Mayones'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1559715541-5daf8a0296d0?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                              RecipeCard(
                                title: 'Sup Sayuran',
                                ingredients: const ['Wortel', 'Kentang'],
                                missingIngredients: const ['Brokoli', 'Kaldu'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                            ],
                          ),
                          // Favorites Tab
                          GridView.count(
                            padding: const EdgeInsets.only(top: 16),
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              RecipeCard(
                                title: 'Nasi Goreng Spesial',
                                ingredients: const ['Telur', 'Wortel'],
                                missingIngredients: const ['Nasi', 'Kecap'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                              RecipeCard(
                                title: 'Smoothie Apel',
                                ingredients: const ['Apel', 'Susu UHT'],
                                missingIngredients: const ['Madu', 'Es Batu'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1589733955941-5eeaf752f6dd?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80',
                              ),
                            ],
                          ),
                          // History Tab
                          GridView.count(
                            padding: const EdgeInsets.only(top: 16),
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              RecipeCard(
                                title: 'Telur Dadar Spesial',
                                ingredients: const ['Telur', 'Tomat'],
                                missingIngredients: const ['Daun Bawang'],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1606851094291-6efae152bb87?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                              ),
                              RecipeCard(
                                title: 'Tumis Bayam Tomat',
                                ingredients: const ['Bayam', 'Tomat', 'Bawang'],
                                missingIngredients: const [],
                                imageUrl:
                                    'https://images.unsplash.com/photo-1576866209830-589e1bfbaa4d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
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
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}
