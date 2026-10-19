import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = 'standard';

  final List<Map<String, dynamic>> plans = [
    {
      'id': 'starter',
      'title': 'Starter',
      'price': '1490',
      'period': '₸/мес',
      'description': '50 запросов к ИИ\nБазовая аналитика',
      'popular': false,
    },
    {
      'id': 'standard',
      'title': 'Standard',
      'price': '3290',
      'period': '₸/мес',
      'description': 'Безлимитный AI-ментор\nПолная аналитика\nРодительский контроль',
      'popular': true,
    },
    {
      'id': 'premium',
      'title': 'Premium',
      'price': '4990',
      'period': '₸/мес',
      'description': 'Всё из Standard\n+ Видео-разборы\n+ Приоритетная поддержка',
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка на AI-ментора'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите план',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Получите полного персонального финансового помощника',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = selectedPlan == plan['id'];

                  return GestureDetector(
                    onTap: () => setState(() => selectedPlan = plan['id']),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(plan['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      if (plan['popular'])
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text('Самый популярный', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(plan['description'], style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${plan['price']} ${plan['period']}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // TODO: Здесь будет логика оплаты
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Оплата ${selectedPlan.toUpperCase()} — в разработке')),
                  );
                },
                child: const Text('Купить подписку', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}