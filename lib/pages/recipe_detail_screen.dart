import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String title;
  final List<String> ingredients;
  final List<String> missingIngredients;
  final String imageUrl;

  // Cooking steps/instructions for the recipe
  final List<Map<String, dynamic>> cookingSteps;

  const RecipeDetailScreen({
    Key? key,
    required this.title,
    required this.ingredients,
    required this.missingIngredients,
    required this.imageUrl,
    required this.cookingSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    width: double.infinity,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recipe title and information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(Icons.access_time, '30 menit'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.local_fire_department, '320 kal'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.people, '2 porsi'),
                    ],
                  ),

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // Ingredients section
                  const Text(
                    'Bahan-bahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Available ingredients
                  if (ingredients.isNotEmpty) ...[
                    ...ingredients.map(
                      (ingredient) =>
                          _buildIngredientItem(ingredient, isAvailable: true),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Missing ingredients
                  if (missingIngredients.isNotEmpty) ...[
                    ...missingIngredients.map(
                      (ingredient) =>
                          _buildIngredientItem(ingredient, isAvailable: false),
                    ),
                  ],

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // Cooking instructions section
                  const Text(
                    'Cara Memasak',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Cooking steps
                  ...List.generate(
                    cookingSteps.length,
                    (index) => _buildCookingStep(
                      index + 1,
                      cookingSteps[index]['instruction'],
                      cookingSteps[index]['imageUrl'],
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient, {required bool isAvailable}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.remove_circle_outline,
            color: isAvailable ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            ingredient,
            style: TextStyle(
              fontSize: 16,
              color: isAvailable ? Colors.black : Colors.grey[600],
              decoration:
                  isAvailable
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
            ),
          ),
          const Spacer(),
          if (!isAvailable)
            OutlinedButton.icon(
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Beli', style: TextStyle(fontSize: 12)),
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCookingStep(
    int stepNumber,
    String instruction,
    String? stepImageUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instruction, style: const TextStyle(fontSize: 16)),
                if (stepImageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      stepImageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
