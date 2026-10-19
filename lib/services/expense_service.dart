import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Добавить трату (автоматически обновляет баланс)
  Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String expenseId = _db.child('expenses/${user.uid}').push().key!;
    
    await _db.child('expenses/${user.uid}/$expenseId').set({
      'amount': amount,
      'category': category,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'type': 'expense',
    });
    
    // Обновляем баланс и общую сумму расходов
    await _updateBalanceAfterExpense(user.uid, amount);
  }

  // Добавить доход (ЗП)
  Future<void> addIncome({
    required double amount,
    required String description,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String incomeId = _db.child('salaries/${user.uid}').push().key!;
    
    await _db.child('salaries/${user.uid}/$incomeId').set({
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'type': 'income',
    });
    
    // Обновляем баланс
    await _updateBalanceAfterIncome(user.uid, amount);
  }

  // Обновление баланса после расхода
  Future<void> _updateBalanceAfterExpense(String userId, double amount) async {
    final userRef = _db.child('users/$userId');
    final snapshot = await userRef.get();
    
    if (snapshot.exists) {
      double currentBalance = (snapshot.child('balance').value as num?)?.toDouble() ?? 0;
      double totalExpense = (snapshot.child('totalExpense').value as num?)?.toDouble() ?? 0;
      
      await userRef.update({
        'balance': currentBalance - amount,
        'totalExpense': totalExpense + amount,
      });
    } else {
      // Если записи пользователя нет, создаём её
      await userRef.set({
        'balance': -amount,
        'totalExpense': amount,
        'totalIncome': 0,
      });
    }
  }

  // Обновление баланса после дохода
  Future<void> _updateBalanceAfterIncome(String userId, double amount) async {
    final userRef = _db.child('users/$userId');
    final snapshot = await userRef.get();
    
    if (snapshot.exists) {
      double currentBalance = (snapshot.child('balance').value as num?)?.toDouble() ?? 0;
      double totalIncome = (snapshot.child('totalIncome').value as num?)?.toDouble() ?? 0;
      
      await userRef.update({
        'balance': currentBalance + amount,
        'totalIncome': totalIncome + amount,
      });
    } else {
      // Если записи пользователя нет, создаём её
      await userRef.set({
        'balance': amount,
        'totalExpense': 0,
        'totalIncome': amount,
      });
    }
  }

  // Получить данные пользователя (баланс)
  Stream<DatabaseEvent> getUserDataStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return _db.child('users/${user.uid}').onValue;
  }

  // Получить все траты пользователя
  Stream<DatabaseEvent> getExpensesStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return _db.child('expenses/${user.uid}').onValue;
  }

  // Получить все доходы пользователя
  Stream<DatabaseEvent> getIncomesStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return _db.child('salaries/${user.uid}').onValue;
  }

  // Удалить трату
  Future<void> deleteExpense(String expenseId, double amount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Возвращаем деньги обратно в баланс
    final userRef = _db.child('users/${user.uid}');
    final snapshot = await userRef.get();
    
    if (snapshot.exists) {
      double currentBalance = (snapshot.child('balance').value as num?)?.toDouble() ?? 0;
      double totalExpense = (snapshot.child('totalExpense').value as num?)?.toDouble() ?? 0;
      
      await userRef.update({
        'balance': currentBalance + amount,
        'totalExpense': totalExpense - amount,
      });
    }
    
    await _db.child('expenses/${user.uid}/$expenseId').remove();
  }

  // Удалить доход
  Future<void> deleteIncome(String incomeId, double amount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Вычитаем из баланса
    final userRef = _db.child('users/${user.uid}');
    final snapshot = await userRef.get();
    
    if (snapshot.exists) {
      double currentBalance = (snapshot.child('balance').value as num?)?.toDouble() ?? 0;
      double totalIncome = (snapshot.child('totalIncome').value as num?)?.toDouble() ?? 0;
      
      await userRef.update({
        'balance': currentBalance - amount,
        'totalIncome': totalIncome - amount,
      });
    }
    
    await _db.child('salaries/${user.uid}/$incomeId').remove();
  }
}