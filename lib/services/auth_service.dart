import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Регистрация с автоматическим входом и созданием записи о балансе
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Создаём запись о пользователе в БД после успешной регистрации
      if (result.user != null) {
        final userId = result.user!.uid;
        await _db.child('users/$userId').set({
          'email': email,
          'balance': 0,
          'totalIncome': 0,
          'totalExpense': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка регистрации в Auth: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      return null;
    }
  }

  // Вход
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Ошибка входа: $e');
      return null;
    }
  }

  // Выход
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Текущий пользователь
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

void debugPrint(String message) {
  print(message);
}