import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/expense_service.dart';

class IncomeHistoryScreen extends StatefulWidget {
  const IncomeHistoryScreen({super.key});

  @override
  State<IncomeHistoryScreen> createState() => _IncomeHistoryScreenState();
}

class _IncomeHistoryScreenState extends State<IncomeHistoryScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final ExpenseService _expenseService = ExpenseService();
  List<Map<String, dynamic>> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  void _loadIncomes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _db.child('salaries/${user.uid}').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      List<Map<String, dynamic>> incomeList = [];

      if (data != null) {
        data.forEach((key, value) {
          Map<String, dynamic> income = Map<String, dynamic>.from(value);
          income['id'] = key;
          incomeList.add(income);
        });
        
        incomeList.sort((a, b) => b['date'].compareTo(a['date']));
      }

      setState(() {
        _incomes = incomeList;
        _isLoading = false;
      });
    });
  }

  Future<void> _deleteIncome(String id, double amount) async {
    await _expenseService.deleteIncome(id, amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись удалена')),
      );
    }
  }

  void _showDeleteDialog(String id, double amount) {
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
              _deleteIncome(id, amount);
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
        title: const Text('История доходов'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incomes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Нет записей о доходах',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Добавить доход'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incomes.length,
                  itemBuilder: (context, index) {
                    final income = _incomes[index];
                    final date = DateTime.parse(income['date']);
                    final formattedDate = '${date.day}.${date.month}.${date.year}';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          child: const Icon(Icons.attach_money, color: Colors.green),
                        ),
                        title: Text(
                          income['description'] ?? 'Без описания',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(formattedDate),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${(income['amount'] as num).toInt()} ₸',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _showDeleteDialog(income['id'], (income['amount'] as num).toDouble()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}