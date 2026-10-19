import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_expense_screen.dart';

class CategoryExpensesScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryName;
  final Color categoryColor;

  const CategoryExpensesScreen({
    super.key,
    required this.categoryKey,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryExpensesScreen> createState() => _CategoryExpensesScreenState();
}

class _CategoryExpensesScreenState extends State<CategoryExpensesScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _expenses = [];
  double _total = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _db.child('expenses/${user.uid}').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      List<Map<String, dynamic>> filtered = [];
      double sum = 0;

      if (data != null) {
        data.forEach((key, value) {
          Map<String, dynamic> expense = Map<String, dynamic>.from(value);
          expense['id'] = key;
          
          if (expense['category'] == widget.categoryKey) {
            filtered.add(expense);
            sum += (expense['amount'] as num).toDouble();
          }
        });
        
        // Сортируем по дате (новые сверху)
        filtered.sort((a, b) => b['date'].compareTo(a['date']));
      }

      setState(() {
        _expenses = filtered;
        _total = sum;
        _isLoading = false;
      });
    });
  }

  Future<void> _deleteExpense(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _db.child('expenses/${user.uid}/$id').remove();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись удалена')),
      );
    }
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Карточка с общей суммой
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.categoryColor, widget.categoryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Общая сумма расходов',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_total ₸',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Кнопка добавления траты
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
                if (result == true) {
                  _loadExpenses();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить трату'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: widget.categoryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Список расходов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет трат в этой категории',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите кнопку "+" чтобы добавить',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          final date = DateTime.parse(expense['date']);
                          final formattedDate = '${date.day}.${date.month}.${date.year}';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: widget.categoryColor.withValues(alpha: 0.2),
                                child: Icon(
                                  Icons.attach_money,
                                  color: widget.categoryColor,
                                ),
                              ),
                              title: Text(
                                expense['description'] ?? 'Без описания',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(formattedDate),
                              trailing: Text(
                                '${(expense['amount'] as num).toInt()} ₸',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: widget.categoryColor,
                                ),
                              ),
                              onLongPress: () => _showDeleteDialog(expense['id']),
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