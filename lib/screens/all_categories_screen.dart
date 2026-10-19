import 'package:flutter/material.dart';
import 'category_expenses_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  final List<Map<String, dynamic>> allCategories = const [
    {'name': '🍔 Еда', 'key': 'food', 'color': Colors.orange},
    {'name': '🎮 Игры', 'key': 'games', 'color': Colors.purple},
    {'name': '📚 Обучение', 'key': 'education', 'color': Colors.blue},
    {'name': '🧸 Игрушки', 'key': 'toys', 'color': Colors.pink},
    {'name': '🍦 Сладости', 'key': 'sweets', 'color': Colors.red},
    {'name': '🎬 Развлечения', 'key': 'entertainment', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все категории'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryExpensesScreen(
                    categoryKey: category['key']!,
                    categoryName: category['name']!,
                    categoryColor: category['color'] as Color,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: (category['color'] as Color).withValues(alpha: 0.1), shape: BoxShape.circle), child: Text(category['name']!, style: const TextStyle(fontSize: 32))),
                  const SizedBox(height: 12),
                  Text(category['name']!.replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ''), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Добавить трату →', style: TextStyle(fontSize: 12, color: category['color'] as Color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}