import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'category_expenses_screen.dart';
import 'all_categories_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  int _touchedIndex = -1;

  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _categoryExpenses = {};

  final List<Map<String, dynamic>> allCategories = [
    {'name': '🍔 Еда', 'key': 'food', 'color': Colors.orange},
    {'name': '🎮 Игры', 'key': 'games', 'color': Colors.purple},
    {'name': '📚 Обучение', 'key': 'education', 'color': Colors.blue},
    {'name': '🧸 Игрушки', 'key': 'toys', 'color': Colors.pink},
    {'name': '🍦 Сладости', 'key': 'sweets', 'color': Colors.red},
    {'name': '🎬 Развлечения', 'key': 'entertainment', 'color': Colors.green},
  ];

  List<Map<String, dynamic>> get displayedCategories => allCategories.take(2).toList();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _db.child('users/${user.uid}').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _balance = (data['balance'] as num?)?.toDouble() ?? 0;
        _totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0;
        _totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0;
      });
    });

    _db.child('expenses/${user.uid}').onValue.listen((event) {
      if (!mounted) return;
      final Map<String, double> newExpenses = {};
      if (event.snapshot.value != null) {
        final expenses = Map<String, dynamic>.from(event.snapshot.value as Map);
        for (final entry in expenses.values) {
          final exp = Map<String, dynamic>.from(entry as Map);
          final cat = exp['category'] as String? ?? '';
          final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
          newExpenses[cat] = (newExpenses[cat] ?? 0) + amount;
        }
      }
      setState(() => _categoryExpenses = newExpenses);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const LoginScreen();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('BudgetSnap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
            onPressed: () => MyApp.of(context)?.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.quiz),
            tooltip: 'Финансовый тест',
            onPressed: () => Navigator.pushNamed(context, '/quiz'),
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Помощник',
            onPressed: () => Navigator.pushNamed(context, '/ai-chat'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Кошелёк
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('💰 Мой кошелёк',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.account_balance_wallet, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${_balance.toStringAsFixed(0)} ₸',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('📈 Доход', _totalIncome),
                        _buildStatCard('📉 Расход', _totalExpense),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_categoryExpenses.isNotEmpty)
              _buildExpensesChart(_categoryExpenses, isDark),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/quiz'),
                icon: const Icon(Icons.quiz),
                label: const Text('Проверь знания финансов 🧠',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const AddIncomeScreen()));
                },
                icon: const Icon(Icons.attach_money),
                label: const Text('Запись дохода',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Категории расходов',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AllCategoriesScreen()));
                    },
                    child: const Text('Все категории →'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: displayedCategories.length,
              itemBuilder: (context, index) {
                final category = displayedCategories[index];
                return _buildCategoryCard(category, isDark);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildExpensesChart(Map<String, double> categoryExpenses, bool isDark) {
    final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);
    final entries = categoryExpenses.entries.toList();

    final sections = entries.asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      final cat = allCategories.firstWhere(
        (c) => c['key'] == entry.key,
        orElse: () => {'name': entry.key, 'key': entry.key, 'color': Colors.grey},
      );
      final isTouched = i == _touchedIndex;
      final percent = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: cat['color'] as Color,
        value: entry.value,
        title: isTouched
            ? '${(cat['name'] as String).split(' ')[0]}\n$percent%'
            : '$percent%',
        radius: isTouched ? 70 : 55,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Расходы по категориям',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.map((e) {
              final cat = allCategories.firstWhere(
                (c) => c['key'] == e.key,
                orElse: () =>
                    {'name': e.key, 'key': e.key, 'color': Colors.grey},
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${cat['name']} — ${e.value.toStringAsFixed(0)} ₸',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text('${amount.toStringAsFixed(0)} ₸',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryExpensesScreen(
              categoryKey: category['key'],
              categoryName: category['name'],
              categoryColor: category['color'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: category['color'].withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Text(category['name'],
                  style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              category['name']
                  .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ''),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text('Добавить трату →',
                style: TextStyle(fontSize: 12, color: category['color'])),
          ],
        ),
      ),
    );
  }
}